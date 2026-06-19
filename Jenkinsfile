pipeline {
  agent {
    kubernetes {
      yamlFile 'build-agent.yaml'
      defaultContainer 'maven'
      idleMinutes 1
    }
  }
  stages {
    stage('Build') {
      parallel {
        stage('Compile') {
          steps {
            container('maven') {
              sh 'mvn compile'
            }
          }
        }
      }
    }
    stage('Test') {
      parallel {
        stage('Unit Tests') {
          steps {
            container('maven') {
              sh 'mvn test'
            }
          }
        }
        stage('OWASP Dependency Check') {
          steps {
            container('maven') {
              catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {

                sh '''
                  set -e

                  echo "== Run dependency check (NO update) =="
                  mvn -B org.owasp:dependency-check-maven:check \
                    -DnvdApiUrl=https://services.nvd.nist.gov/rest/json/cves/2.0 \
                    -DautoUpdate=false
                '''
              }
            }
          }

          post {
            always {
              archiveArtifacts artifacts: 'target/dependency-check-report.html',
                              allowEmptyArchive: true,
                              fingerprint: true
            }
          }
        }
      }
    }
    
    stage('Package') {
      parallel {
        stage('Create Jarfile') {
          steps {
            container('maven') {
              sh 'mvn package -DskipTests'
            }
          }
        }
        stage('OCI Image BnP') {
          steps {
            container('kaniko') {
              sh '/kaniko/executor -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=ferhatvurucu/dso-demo'
            }
          }
        }
      }
    }
    

    stage('Deploy to Dev') {
      steps {
        // TODO
        sh "echo done"
      }
    }
  }
}
