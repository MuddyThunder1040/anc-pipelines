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
                                echo "[STATE BACKUP]"
                                cp terraform.tfstate /tmp/terraform-state-${params.TF_MODULE}.tfstate
                                echo "💾 State backed up to /tmp/terraform-state-${params.TF_MODULE}.tfstate"
                            else
                                echo "❌ No terraform.tfstate file found"
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
                        // Save state file for future runs
                        sh """
                            echo "Directory: \$(pwd)"
                            echo "Module: ${params.TF_MODULE}"
                            echo "Operation: ${params.TF_OPERATION}"
                            
                            # Save state file if it exists
                            if [ -f terraform.tfstate ]; then
                                echo "[INFO] Saving state file for future runs"
                                cp terraform.tfstate /tmp/terraform-state-${params.TF_MODULE}.tfstate
                                echo "[INFO] State file saved to /tmp/terraform-state-${params.TF_MODULE}.tfstate"
                                echo "[INFO] State file size: \$(du -h terraform.tfstate | cut -f1)"
                            else
                                echo "[INFO] No state file to save"
                            fi
                            
                            terraform state list 2>/dev/null | head -10 || echo "No resources"
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "\u001B[35m[END]\u001B[0m Finished: ${params.TF_OPERATION} on ${params.TF_MODULE} (${params.Branch})"
        }
        success {
            echo "\u001B[32m[SUCCESS]\u001B[0m Terraform operation succeeded"
        }
        failure {
            echo "\u001B[31m[FAIL]\u001B[0m Terraform operation failed"
        }
    }
}
