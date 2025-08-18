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
                            echo "\u001B[31m[ERROR]\u001B[0m Module directory aws-topology/${params.TF_MODULE} not found!"
                            exit 1
                        fi
                        echo "\u001B[32m[SUCCESS]\u001B[0m Module directory found: aws-topology/${params.TF_MODULE}"
                    """
                }
            }
        }

        stage("Init & Validate") {
            steps {
                echo "\u001B[34m[INFO]\u001B[0m Init & Validate"
                script {
                    dir("aws-topology/${params.TF_MODULE}") {
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
                                    echo "\u001B[36m[PLAN SUMMARY]\u001B[0m"
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
                                    echo "\u001B[31m[WARNING]\u001B[0m This will destroy infrastructure!"
                                    terraform plan -destroy ${tfVarFile} -out=destroy-plan
                                    terraform show -no-color destroy-plan | head -30
                                    terraform apply destroy-plan
                                """
                                break
                            case 'show':
                                sh """
                                    echo "\u001B[36m[CURRENT STATE]\u001B[0m"
                                    terraform show -no-color
                                    echo ""
                                    echo "\u001B[36m[STATE LIST]\u001B[0m"
                                    terraform show"
                                """
                                break
                            case 'init':
                                sh "terraform init -upgrade -reconfigure"
                                break
                            case 'validate':
                                sh "terraform validate"
                                break
                            default:
                                error "\u001B[31m[ERROR]\u001B[0m Unknown operation: ${params.TF_OPERATION}"
                        }
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
                            echo "\u001B[36mDirectory:\u001B[0m \$(pwd)"
                            echo "\u001B[36mModule:\u001B[0m ${params.TF_MODULE}"
                            echo "\u001B[36mOperation:\u001B[0m ${params.TF_OPERATION}"
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
