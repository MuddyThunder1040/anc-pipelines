pipeline {
    agent any

    stages {
        stage ("🔍 Source Checkout") {
            steps {
                echo "=== CHECKING OUT EXPRESS APP ==="
                echo ""
                echo "📥 Cloning repository from GitHub..."
                git url: 'https://github.com/MuddyThunder1040/appserver.git', branch: 'main'
                echo "✅ Source code ready"
            }
        }
        
        stage ("🔧 Environment Setup") {
            steps {
                echo "=== ENVIRONMENT SETUP ==="
                echo ""
                echo "📋 Node.js Environment:"
                sh 'node --version'
                sh 'npm --version'
                echo ""
            }
        }
        
        stage ("📦 Dependencies") {
            steps {
                echo "=== INSTALLING DEPENDENCIES ==="
                echo ""
                echo "📥 Installing npm packages..."
                sh 'npm install'
                echo "✅ Dependencies installed"
            }
        }
        
        stage ("🚀 Deploy App") {
            steps {
                echo "=== DEPLOYING EXPRESS APPLICATION ==="
                echo ""
                echo "🛑 Stopping existing services..."
                sh 'pkill -f "node server.js" || true'
                echo ""
                echo "🚀 Starting Express server..."
                sh 'nohup node server.js > app.log 2>&1 &'
                sh 'sleep 3'
                echo ""
                echo "🔍 Health check..."
                sh 'curl -f http://localhost:3000 || exit 1'
                echo "✅ Application deployed successfully!"
            }
        }
    }
    
    post {
        always {
            echo "🏁 === EXPRESS APP PIPELINE COMPLETED ==="
        }
        success {
            echo "🎉 Express app is running at http://localhost:3000"
        }
        failure {
            echo "❌ Deployment failed - check logs for details"
        }
    }
}
