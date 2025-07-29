pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/MuddyThunder1040/aws-topology.git'
        REPO_DIR = 'aws-topology/Local/'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git url: "${REPO_URL}", branch: 'master'
            }
        }
        stage('Terraform Init') {
            steps {
                dir("${REPO_DIR}") {
                    sh 'terraform init'
                }
            }
        }
        stage('Terraform Plan') {
            steps {
                dir("${REPO_DIR}") {
                    sh 'terraform plan'
                }
            }
        }
        stage('Terraform Apply') {
            steps {
                dir("${REPO_DIR}") {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
}