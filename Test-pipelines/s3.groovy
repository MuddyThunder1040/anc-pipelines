pipeline{
    agent any 
    stages {
        stage('Aws s3 buckets show') {
            steps {
                echo 'Showing AWS S3 buckets...'
                sh 'aws s3 ls'
            }
        }
    }
}