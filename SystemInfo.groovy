pipeline {
    agent any

    stages {
        stage ("Connection Established") {
            steps {
                echo "✅ Connection Established"
                sh 'curl --max-time 5 google.com'
            }
        }
        stage ("System Info") {
            steps {
                echo "=== SYSTEM INFORMATION ==="
                echo ""
                echo "📋 Operating System & Kernel Info:"
                sh 'uname -a'
                echo ""
                echo "💾 Disk Usage:"
                sh 'df -h'
                echo ""
                echo "⏰ System Uptime & Load:"
                sh 'uptime'
                echo ""
            }
        }
    }
    
    post {
        always {
            echo "🏁 === PIPELINE COMPLETED ==="
        }
    }
}