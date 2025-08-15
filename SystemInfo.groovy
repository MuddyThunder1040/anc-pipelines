pipeline {
    agent any

    stages {
        stage('Collect System Info') {
            steps {
                script {
                    def sysInfo = ""
                    if (isUnix()) {
                        sysInfo = sh(script: 'uname -a && lsb_release -a || cat /etc/os-release && free -h && df -h', returnStdout: true)
                    } else {
                        sysInfo = bat(script: 'systeminfo', returnStdout: true)
                    }
                    writeFile file: 'systeminfo.txt', text: sysInfo
                }
            }
        }
        stage('Archive System Info') {
            steps {
                archiveArtifacts artifacts: 'systeminfo.txt', onlyIfSuccessful: true
            }
        }
    }
}