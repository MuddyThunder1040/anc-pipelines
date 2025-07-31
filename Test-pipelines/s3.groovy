pipeline{
    agent any 
    environment {
        Aws_ACCESS_KEY_ID = credentials('Aws-cli')
        Aws_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }
    stages {
        stage('Use AWS CLI') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'Aws-cli',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        echo "Verifying AWS Identity..."
                        aws sts get-caller-identity

                        echo "Listing S3 Buckets..."
                        aws s3 ls
                    '''
                }
            }
        stage('Aws s3 buckets show') {
            steps {
                echo 'Showing AWS S3 buckets...'
                sh 'aws s3 ls'
            }
        }
    }
}