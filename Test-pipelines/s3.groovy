pipeline {
    agent any
    stages {
        stage('AWS S3 Operations') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'Aws-cli',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY',
                        hideUsernameParameter: true,
                        hidePasswordParameter: true
                    )
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        echo "Verifying AWS Identity..."
                        aws sts get-caller-identity

                        echo "Listing S3 Buckets..."
                        aws s3 ls
                    '''
                }
            }
        }
    }
}
