pipeline{
    agent any 
    environment {
        Aws_ACCESS_KEY_ID = credentials('Aws-cli')
        Aws_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }
    stages {
        stage('Aws s3 buckets show') {
            steps {
                echo 'Showing AWS S3 buckets...'
                sh 'aws s3 ls'
            }
        }
    }
}