pipeline {
    agent any

    stages {
        stage ("Connection Established") {
            steps {
                echo "\u001B[32mConnection Established\u001B[0m"
            }
            steps {
                sh 'curl --max-time 5 google.com'
            }
        }
        stage ("System Info") {
            steps {
                echo "\u001B[34m=== SYSTEM INFORMATION ===\"
                
                echo "\u001B[33m📋 Operating System & Kernel Info:\u001B[0m"
                sh 'uname -a'
                
                echo "\u001B[33m💾 Disk Usage:\u001B[0m"
                sh 'df -h'
                
                echo "\u001B[33m🧠 Memory Usage:\u001B[0m"
                sh 'free -m'
                
                echo "\u001B[33m⏰ System Uptime & Load:\u001B[0m"
                sh 'uptime'
                
                echo "\u001B[32m✅ System Info Collection Complete\u001B[0m"
            }
        }
    }
}