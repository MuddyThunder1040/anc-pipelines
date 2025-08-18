pipeline {
    agent any
    parameters {
        choice(name: 'TF_OPERATION', choices: ['plan', 'apply', 'destroy', 'show', 'init', 'validate'], description: 'Select the Terraform operation to perform')
        choice(name: 'TF_MODULE', choices: ['Local', 'S3', 'VPC'], description: 'Select the Terraform module to operate on')
        string(name: 'Branch', defaultValue: 'master', description: 'Git branch to use')
        booleanParam(name: 'PLAN_ONLY', defaultValue: false, description: 'Run plan only without apply (safety check)')
        string(name: 'TF_VAR_FILE', defaultValue: '', description: 'Optional: Terraform variables file (e.g., terraform.tfvars)')
    }
    
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
    }
    stages {
        stage("Checkout") {
            steps {
                echo "\u001B[34m[INFO]\u001B[0m Checking out source (Branch: ${params.Branch}, Module: ${params.TF_MODULE})"
                script {
                    sh 'rm -rf aws-topology || true'
                    sh "git clone -b ${params.Branch} --single-branch https://github.com/MuddyThunder1040/aws-topology.git"
                    sh """
                        if [ ! -d "aws-topology/${params.TF_MODULE}" ]; then
                            echo "[ERROR] Module directory aws-topology/${params.TF_MODULE} not found!"
                            exit 1
                        fi
                        echo "[SUCCESS] Module directory found: aws-topology/${params.TF_MODULE}"
                    """
                }
            }
        }

        stage("Init & Validate") {
            steps {
                echo "\u001B[34m[INFO]\u001B[0m Init & Validate"
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
                        // Restore previous state file if it exists
                        sh """
                            echo "[INFO] Checking for existing state file..."
                            if [ -f "/tmp/terraform-state-${params.TF_MODULE}.tfstate" ]; then
                                echo "[INFO] Restoring previous state file"
                                cp /tmp/terraform-state-${params.TF_MODULE}.tfstate terraform.tfstate
                                echo "[INFO] State file restored from /tmp/terraform-state-${params.TF_MODULE}.tfstate"
                            else
                                echo "[INFO] No previous state file found"
                            fi
                        """
                        
                        sh """
                            terraform init -upgrade
                            terraform validate
                        """
                    }
                }
            }
        }

        stage("Execute Terraform Operation") {
            steps {
                echo "\u001B[34m[INFO]\u001B[0m Running: ${params.TF_OPERATION}"
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
                        def tfVarFile = params.TF_VAR_FILE ? "-var-file=${params.TF_VAR_FILE}" : ""
                        switch(params.TF_OPERATION) {
                            case 'plan':
                                sh """
                                    terraform plan ${tfVarFile} -out=tfplan
                                    echo "[PLAN SUMMARY]"
                                    terraform show -no-color tfplan | head -30
                                """
                                break
                            case 'apply':
                                if (params.PLAN_ONLY) {
                                    sh "terraform plan ${tfVarFile}"
                                } else {
                                    sh """
                                        terraform plan ${tfVarFile} -out=tfplan
                                        terraform apply tfplan
                                    """
                                }
                                break
                            case 'destroy':
                                sh """
                                    echo "[WARNING] This will destroy infrastructure!"
                                    terraform plan -destroy ${tfVarFile} -out=destroy-plan
                                    terraform show -no-color destroy-plan | head -30
                                    terraform apply destroy-plan
                                """
                                break
                            case 'show':
                                sh """
                                    echo "[CURRENT STATE]"
                                    if [ -f terraform.tfstate ]; then
                                        echo "State file found: terraform.tfstate"
                                        terraform show -no-color
                                        if [ -s terraform.tfstate ]; then
                                            echo ""
                                            echo "[STATE FILE CONTENT SUMMARY]"
                                            cat terraform.tfstate | jq -r '.resources[]?.type + "." + .resources[]?.name' 2>/dev/null || echo "State file exists but may be empty or invalid JSON"
                                        fi
                                    else
                                        echo "No terraform.tfstate file found"
                                        terraform show -no-color 2>/dev/null || echo "No state available"
                                    fi
                                    echo ""
                                    echo "[STATE LIST]"
                                    terraform state list 2>/dev/null || echo "No resources in state"
                                    echo ""
                                    echo "[WORKSPACE INFO]"
                                    terraform workspace show 2>/dev/null || echo "Default workspace"
                                    echo ""
                                    echo "[CONFIGURATION PREVIEW]"
                                    echo "Terraform files in current directory:"
                                    ls -la *.tf 2>/dev/null || echo "No .tf files found"
                                """
                                break
                            case 'init':
                                sh "terraform init -upgrade -reconfigure"
                                break
                            case 'validate':
                                sh "terraform validate"
                                break
                            default:
                                error "[ERROR] Unknown operation: ${params.TF_OPERATION}"
                        }
                    }
                }
            }
        }

        stage("State Management") {
            steps {
                echo "\u001B[34m[INFO]\u001B[0m Managing Terraform State"
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
                        sh """
                            echo "[STATE FILE CHECK]"
                            if [ -f terraform.tfstate ]; then
                                echo "✅ terraform.tfstate exists"
                                echo "📊 State file size: \$(du -h terraform.tfstate | cut -f1)"
                                echo "📅 State file modified: \$(stat -c %y terraform.tfstate 2>/dev/null || stat -f %Sm terraform.tfstate)"
                                
                                echo ""
                                echo "[STATE ARCHIVING]"
                                # Create archive directory structure
                                mkdir -p ../../terraform-archives/${params.TF_MODULE}
                                
                                # Generate timestamp for unique archive naming
                                TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
                                BUILD_ID="${env.BUILD_NUMBER}"
                                ARCHIVE_NAME="terraform-state-${params.TF_MODULE}-\${BUILD_ID}-\${TIMESTAMP}-${params.TF_OPERATION}"
                                
                                # Archive current state with metadata
                                cp terraform.tfstate ../../terraform-archives/${params.TF_MODULE}/\${ARCHIVE_NAME}.tfstate
                                
                                # Create metadata file
                                cat > ../../terraform-archives/${params.TF_MODULE}/\${ARCHIVE_NAME}.meta << EOF
{
  "build_number": "${env.BUILD_NUMBER}",
  "operation": "${params.TF_OPERATION}",
  "module": "${params.TF_MODULE}",
  "branch": "${params.Branch}",
  "timestamp": "\$(date -Iseconds)",
  "jenkins_job": "${env.JOB_NAME}",
  "user": "jenkins",
  "workspace": "\$(terraform workspace show)",
  "state_size": "\$(du -b terraform.tfstate | cut -f1)"
}
EOF
                                
                                echo "💾 State archived as: \${ARCHIVE_NAME}.tfstate"
                                echo "📋 Metadata saved as: \${ARCHIVE_NAME}.meta"
                                
                                # Also backup to /tmp for quick restore
                                cp terraform.tfstate /tmp/terraform-state-${params.TF_MODULE}.tfstate
                                echo "🔄 Quick backup saved to /tmp/terraform-state-${params.TF_MODULE}.tfstate"
                                
                                # Show archive summary
                                echo ""
                                echo "[ARCHIVE SUMMARY]"
                                echo "Total archives for ${params.TF_MODULE}:"
                                ls -la ../../terraform-archives/${params.TF_MODULE}/ | grep -E '\\.(tfstate|meta)$' | wc -l
                                echo "Latest 5 archives:"
                                ls -lt ../../terraform-archives/${params.TF_MODULE}/*.tfstate 2>/dev/null | head -5 | awk '{print \$9, \$5, \$6, \$7, \$8}' || echo "No previous archives"
                                
                            else
                                echo "❌ No terraform.tfstate file found"
                                echo "📝 Creating empty archive entry for operation: ${params.TF_OPERATION}"
                                mkdir -p ../../terraform-archives/${params.TF_MODULE}
                                TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
                                BUILD_ID="${env.BUILD_NUMBER}"
                                echo "No state file - ${params.TF_OPERATION} operation completed" > ../../terraform-archives/${params.TF_MODULE}/no-state-\${BUILD_ID}-\${TIMESTAMP}-${params.TF_OPERATION}.log
                            fi
                            
                            echo ""
                            echo "[CURRENT RESOURCES]"
                            terraform state list 2>/dev/null || echo "No resources in state"
                            
                            echo ""
                            echo "[WORKSPACE STATUS]"
                            echo "Current workspace: \$(terraform workspace show)"
                            echo "Available workspaces:"
                            terraform workspace list 2>/dev/null || echo "Only default workspace"
                        """
                    }
                }
            }
        }

        stage("Summary") {
            steps {
                echo "\u001B[34m[INFO]\u001B[0m Summary"
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
                        sh """
                            echo "Directory: \$(pwd)"
                            echo "Module: ${params.TF_MODULE}"
                            echo "Operation: ${params.TF_OPERATION}"
                            echo "Build: ${env.BUILD_NUMBER}"
                            echo ""
                            
                            # Current state summary
                            echo "[CURRENT STATE]"
                            if [ -f terraform.tfstate ]; then
                                echo "📊 State file size: \$(du -h terraform.tfstate | cut -f1)"
                                RESOURCE_COUNT=\$(terraform state list 2>/dev/null | wc -l)
                                echo "📦 Resources in state: \$RESOURCE_COUNT"
                                terraform state list 2>/dev/null | head -10 || echo "No resources"
                            else
                                echo "❌ No state file present"
                            fi
                            
                            echo ""
                            echo "[ARCHIVE HISTORY]"
                            if [ -d "../../terraform-archives/${params.TF_MODULE}" ]; then
                                ARCHIVE_COUNT=\$(ls ../../terraform-archives/${params.TF_MODULE}/*.tfstate 2>/dev/null | wc -l)
                                echo "📚 Total archived states: \$ARCHIVE_COUNT"
                                echo "📋 Recent archives (last 3):"
                                ls -lt ../../terraform-archives/${params.TF_MODULE}/*.tfstate 2>/dev/null | head -3 | while read line; do
                                    echo "  \$(echo \$line | awk '{print \$9}' | xargs basename) - \$(echo \$line | awk '{print \$6, \$7, \$8}')"
                                done
                            else
                                echo "📭 No archives found yet"
                            fi
                            
                            echo ""
                            echo "[OPERATION SUMMARY]"
                            echo "✅ Operation '${params.TF_OPERATION}' completed on module '${params.TF_MODULE}'"
                            echo "🌿 Branch: ${params.Branch}"
                            echo "🏗️ Build: ${env.BUILD_NUMBER}"
                            echo "📅 Timestamp: \$(date)"
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "\u001B[35m[END]\u001B[0m Finished: ${params.TF_OPERATION} on ${params.TF_MODULE} (${params.Branch})"
            
            script {
                // Archive all terraform artifacts
                try {
                    echo "\u001B[36m[ARCHIVING]\u001B[0m Archiving Terraform artifacts..."
                    
                    // Archive state files and metadata
                    archiveArtifacts artifacts: 'terraform-archives/**/*', allowEmptyArchive: true, fingerprint: true
                    
                    // Archive plan files if they exist
                    dir("aws-topology/${params.TF_MODULE}") {
                        sh """
                            # Archive any plan files
                            if ls *.tfplan >/dev/null 2>&1; then
                                mkdir -p ../../terraform-plans/${params.TF_MODULE}
                                TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
                                for plan in *.tfplan; do
                                    cp "\$plan" "../../terraform-plans/${params.TF_MODULE}/\${plan%.tfplan}-${env.BUILD_NUMBER}-\${TIMESTAMP}.tfplan"
                                done
                                echo "📋 Plan files archived"
                            fi
                            
                            # Archive destroy plans if they exist  
                            if ls destroy-plan >/dev/null 2>&1; then
                                mkdir -p ../../terraform-plans/${params.TF_MODULE}
                                TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
                                cp destroy-plan "../../terraform-plans/${params.TF_MODULE}/destroy-plan-${env.BUILD_NUMBER}-\${TIMESTAMP}.tfplan"
                                echo "🗑️ Destroy plan archived"
                            fi
                        """
                    }
                    
                    // Archive plan files
                    archiveArtifacts artifacts: 'terraform-plans/**/*', allowEmptyArchive: true, fingerprint: true
                    
                    echo "\u001B[32m[SUCCESS]\u001B[0m All artifacts archived successfully"
                    
                } catch (Exception e) {
                    echo "\u001B[33m[WARNING]\u001B[0m Could not archive some artifacts: ${e.getMessage()}"
                }
            }
        }
        success {
            echo "\u001B[32m[SUCCESS]\u001B[0m Terraform operation succeeded"
            script {
                // Additional success actions for state management
                try {
                    sh """
                        echo "[SUCCESS SUMMARY]"
                        echo "Operation: ${params.TF_OPERATION}"
                        echo "Module: ${params.TF_MODULE}"
                        echo "Build: ${env.BUILD_NUMBER}"
                        echo "Archives created: \$(find terraform-archives -name "*.tfstate" 2>/dev/null | wc -l) state files"
                        echo "Total artifacts: \$(find terraform-archives terraform-plans -type f 2>/dev/null | wc -l) files"
                    """
                } catch (Exception e) {
                    echo "Could not generate success summary"
                }
            }
        }
        failure {
            echo "\u001B[31m[FAIL]\u001B[0m Terraform operation failed"
            script {
                // Archive failure state for debugging
                try {
                    sh """
                        echo "[FAILURE ARCHIVING]"
                        mkdir -p terraform-failures/${params.TF_MODULE}
                        TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
                        
                        # Archive any existing state for debugging
                        find aws-topology/${params.TF_MODULE} -name "*.tfstate*" -exec cp {} terraform-failures/${params.TF_MODULE}/ \\; 2>/dev/null || true
                        
                        # Archive logs and error info
                        echo "Build: ${env.BUILD_NUMBER}" > terraform-failures/${params.TF_MODULE}/failure-\${TIMESTAMP}.log
                        echo "Operation: ${params.TF_OPERATION}" >> terraform-failures/${params.TF_MODULE}/failure-\${TIMESTAMP}.log
                        echo "Module: ${params.TF_MODULE}" >> terraform-failures/${params.TF_MODULE}/failure-\${TIMESTAMP}.log
                        echo "Timestamp: \$(date)" >> terraform-failures/${params.TF_MODULE}/failure-\${TIMESTAMP}.log
                        
                        echo "💥 Failure state archived for debugging"
                    """
                    
                    // Archive failure artifacts
                    archiveArtifacts artifacts: 'terraform-failures/**/*', allowEmptyArchive: true
                    
                } catch (Exception e) {
                    echo "Could not archive failure state: ${e.getMessage()}"
                }
            }
        }
    }
}
