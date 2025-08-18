pipeline {
    agent any
    parameters {
        choice(name: 'TF_OPERATION', choices: ['plan', 'apply', 'destroy', 'show', 'init', 'validate'], description: 'Select the Terraform operation to perform')
        choice(name: 'TF_MODULE', choices: ['Local', 'S3', 'VPC'], description: 'Select the Terraform module to operate on')
        string(name: 'Branch', defaultValue: 'main', description: 'Git branch to use')
        booleanParam(name: 'PLAN_ONLY', defaultValue: false, description: 'Run plan only without apply (safety check)')
        string(name: 'TF_VAR_FILE', defaultValue: '', description: 'Optional: Terraform variables file (e.g., terraform.tfvars)')
    }
    
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
    }
    stages {
        stage ("🔍 Source Checkout") {
            steps {
                echo "=== CHECKING OUT TF OPERATIONS ==="
                echo ""
                echo "📥 Cloning repository from GitHub..."
                echo "🌿 Using branch: ${params.Branch}"
                echo "📁 Target module: ${params.TF_MODULE}"
                
                script {
                    // Clean workspace first
                    sh 'rm -rf aws-topology || true'
                    
                    // Clone the repository
                    sh "git clone -b ${params.Branch} --single-branch https://github.com/MuddyThunder1040/aws-topology.git"
                    
                    // Verify the module directory exists
                    sh """
                        if [ ! -d "aws-topology/${params.TF_MODULE}" ]; then
                            echo "❌ Module directory aws-topology/${params.TF_MODULE} not found!"
                            echo "📁 Available directories:"
                            ls -la aws-topology/ || echo "No aws-topology directory found"
                            exit 1
                        fi
                        echo "✅ Module directory verified: aws-topology/${params.TF_MODULE}"
                    """
                }
                
                echo "✅ Source code ready for Terraform operations from branch ${params.Branch}"
                echo "📍 Selected module: ${params.TF_MODULE} | Path: aws-topology/${params.TF_MODULE}"
            }
        }

        stage ("🔧 Environment Setup") {
            steps {
                echo "=== ENVIRONMENT SETUP ==="
                echo ""
                echo "📋 Terraform Environment Information:"
                
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
                        sh """
                            echo "🔍 Current working directory:"
                            pwd
                            echo ""
                            echo "📁 Directory contents:"
                            ls -la
                            echo ""
                            echo "🛠️ Terraform version:"
                            terraform version
                            echo ""
                            echo "☁️ AWS CLI version (if available):"
                            aws --version 2>/dev/null || echo "AWS CLI not available"
                            echo ""
                            echo "🔧 Initializing Terraform..."
                            terraform init -upgrade
                        """
                    }
                }
            }
        }

        stage ("📦 Validation & Dependencies") {
            steps {
                echo "=== TERRAFORM VALIDATION ==="
                echo ""
                
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
                        sh """
                            echo "✅ Validating Terraform configuration..."
                            terraform validate
                            echo ""
                            echo "📥 Getting Terraform modules..."
                            terraform get -update
                            echo ""
                            echo "🔍 Formatting check..."
                            terraform fmt -check -diff || {
                                echo "⚠️ Formatting issues detected. Auto-formatting..."
                                terraform fmt -recursive
                                echo "✅ Files formatted"
                            }
                        """
                    }
                }
                echo "✅ Validation and dependencies completed"
            }
        }
        stage ("🚀 Execute Terraform Operation") {
            steps {
                echo "=== EXECUTING ${params.TF_OPERATION.toUpperCase()} OPERATION ==="
                echo ""
                
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
                        def tfVarFile = params.TF_VAR_FILE ? "-var-file=${params.TF_VAR_FILE}" : ""
                        
                        switch(params.TF_OPERATION) {
                            case 'plan':
                                sh """
                                    echo "📋 Creating Terraform plan..."
                                    terraform plan ${tfVarFile} -out=tfplan
                                    echo "✅ Plan created successfully!"
                                    echo ""
                                    echo "📊 Plan summary:"
                                    terraform show -no-color tfplan | head -50
                                """
                                break
                                
                            case 'apply':
                                if (params.PLAN_ONLY) {
                                    sh """
                                        echo "🔍 PLAN ONLY mode - no changes will be applied"
                                        terraform plan ${tfVarFile}
                                    """
                                } else {
                                    sh """
                                        echo "🚀 Applying Terraform changes..."
                                        terraform plan ${tfVarFile} -out=tfplan
                                        echo ""
                                        echo "📋 Plan review:"
                                        terraform show -no-color tfplan | head -30
                                        echo ""
                                        echo "⚡ Applying changes..."
                                        terraform apply tfplan
                                        echo ""
                                        echo "📊 Current state summary:"
                                        terraform show -no-color | head -20
                                    """
                                }
                                break
                                
                            case 'destroy':
                                sh """
                                    echo "⚠️ DESTROY operation - This will remove infrastructure!"
                                    echo "📋 Creating destroy plan..."
                                    terraform plan -destroy ${tfVarFile} -out=destroy-plan
                                    echo ""
                                    echo "💥 Executing destroy..."
                                    terraform apply destroy-plan
                                    echo "✅ Destroy completed!"
                                """
                                break
                                
                            case 'show':
                                sh """
                                    echo "📊 Current Terraform state:"
                                    terraform show -no-color
                                    echo ""
                                    echo "🗂️ State list:"
                                    terraform state list || echo "No resources in state"
                                """
                                break
                                
                            case 'init':
                                sh """
                                    echo "🔧 Re-initializing Terraform..."
                                    terraform init -upgrade -reconfigure
                                """
                                break
                                
                            case 'validate':
                                sh """
                                    echo "✅ Validating Terraform configuration..."
                                    terraform validate
                                    terraform fmt -check -diff
                                """
                                break
                                
                            default:
                                error "Unknown Terraform operation: ${params.TF_OPERATION}"
                        }
                    }
                }
                echo "✅ ${params.TF_OPERATION.toUpperCase()} operation completed successfully!"
            }
        }
        
        stage ("📊 Post-Operation Summary") {
            steps {
                echo "=== POST-OPERATION SUMMARY ==="
                echo ""
                
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
                        sh """
                            echo "📁 Working directory: \$(pwd)"
                            echo "🏗️ Module: ${params.TF_MODULE}"
                            echo "⚙️ Operation: ${params.TF_OPERATION}"
                            echo "🌿 Branch: ${params.Branch}"
                            echo ""
                            
                            if [ "${params.TF_OPERATION}" != "destroy" ]; then
                                echo "📋 Current resources (if any):"
                                terraform state list 2>/dev/null | head -10 || echo "No resources in state file"
                                echo ""
                                echo "💰 Cost estimation (if available):"
                                echo "Consider running: terraform plan -out=plan && terraform show -json plan | jq '.resource_changes'"
                            fi
                            
                            echo ""
                            echo "📁 Generated files:"
                            ls -la *.tfplan *.tfstate* 2>/dev/null || echo "No plan or state files found"
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "🏁 === TERRAFORM OPERATIONS COMPLETED ==="
            echo "📊 Operation: ${params.TF_OPERATION}"
            echo "📁 Module: ${params.TF_MODULE}"
            echo "🌿 Branch: ${params.Branch}"
        }
        
        success {
            echo "🎉 === TERRAFORM OPERATION SUCCEEDED ==="
            script {
                // Archive important files
                try {
                    dir("aws-topology/${params.TF_MODULE}") {
                        sh '''
                            echo "📦 Archiving Terraform artifacts..."
                            mkdir -p ../../terraform-artifacts
                            cp *.tfplan ../../terraform-artifacts/ 2>/dev/null || echo "No plan files to archive"
                            cp terraform.tfstate* ../../terraform-artifacts/ 2>/dev/null || echo "No state files to archive"
                        '''
                    }
                    archiveArtifacts artifacts: 'terraform-artifacts/*', allowEmptyArchive: true
                } catch (Exception e) {
                    echo "Could not archive artifacts: ${e.getMessage()}"
                }
            }
        }
        
        failure {
            echo "💥 === TERRAFORM OPERATION FAILED ==="
            echo "❌ Check the logs above for details"
            script {
                try {
                    dir("aws-topology/${params.TF_MODULE}") {
                        sh """
                            echo "🔍 Terraform diagnostics:"
                            echo "Current directory: \$(pwd)"
                            echo "Terraform version: \$(terraform version)"
                            echo ""
                            echo "📁 Directory contents:"
                            ls -la
                            echo ""
                            echo "🔧 Terraform configuration validation:"
                            terraform validate || echo "Configuration validation failed"
                            echo ""
                            echo "📄 Recent logs (if any):"
                            tail -20 *.log 2>/dev/null || echo "No log files found"
                        """
                    }
                } catch (Exception e) {
                    echo "Could not retrieve diagnostics: ${e.getMessage()}"
                }
            }
        }
        
        cleanup {
            script {
                // Optional cleanup of large files
                sh """
                    echo "🧹 Cleaning up large temporary files..."
                    find . -name "*.tfplan" -size +10M -delete 2>/dev/null || true
                    echo "✅ Cleanup completed"
                """
            }
        }
    }
}
