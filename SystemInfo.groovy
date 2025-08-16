pipeline {
    agent any

    stages {
        stage ("Connection Established") {
            steps {
                echo "\u001B[32mConnection Established\u001B[0m"
                sh 'curl --max-time 5 google.com'
            }
        }
        stage ("System Info") {
            steps {
                echo "\u001B[34m=== SYSTEM INFORMATION ===\u001B[0m"
                echo ""
                echo "\u001B[33m📋 Operating System & Kernel Info:\u001B[0m"
                sh 'uname -a'
                
                echo "\u001B[33m💾 Disk Usage:\u001B[0m"
                sh 'df -h'
                
                echo "\u001B[33m⏰ System Uptime & Load:\u001B[0m"
                sh 'uptime'
                
            }
        }
        post {
            always {
                echo "\u001B[31m=== PIPELINE COMPLETED ===\u001B[0m"
            }
        }
    }
}