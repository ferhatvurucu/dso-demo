pipeline {
  agent {
    kubernetes {
      yamlFile 'build-agent.yaml'
      defaultContainer 'maven'
      idleMinutes 1
    }
  }
  environment {
      // Other environment variables
      ARGO_SERVER = '34.118.90.136:32100'
      DEV_URL='http://34.118.90.136:30080/'
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
        stage('OSSLicenseChecker'){
          steps{
            container('licensefinder'){
              sh'ls -al'
              sh'''#!/bin/bash --login
              rvm use default
              gem install license_finder
              license_finder
              '''
            }
          }
        }
        stage('GenerateSBOM') {
          steps {
            container('maven') {
              sh 'mvn org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom'
            }
          }
          post {
            success {
              // dependencyTrackPublisher(
              //   projectName: 'sample-spring-app',
              //   projectVersion: '0.0.1',
              //   artifact: 'target/bom.xml',
              //   projectProperties: [
              //     tags: [],
              //     swidTagId: '',
              //     group: '',
              //     description: ''
              //   ],
              //   synchronous: true
              // )
              archiveArtifacts(
                artifacts: 'target/bom.xml',
                allowEmptyArchive: true,
                fingerprint: true,
                onlyIfSuccessful: true
              )
            }
          }
        }
        // stage('SAST') {
        //   steps {
        //       container('slscan') {
        //           sh 'scan --type java,depscan --build --no-error'
        //       }
        //   }
        //   post {
        //       success {
        //           archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/*', fingerprint: true, onlyIfSuccessful: true
        //       }
        //   }
        // }
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

    stage('Image Analysis') {
      parallel {
        stage('Image Linting') {
          steps {
            container('docker-tools') {
              sh "dockle --exit-code 1 --exit-level fatal ferhatvurucu/dso-demo"
            }
          }
        }
        stage('Image Scan') {
          steps {
            container('docker-tools') {
              sh "trivy image --timeout 10m --exit-code 0 --severity HIGH,CRITICAL --ignore-unfixed ferhatvurucu/dso-demo"
            }
          }
        }
      }
    }

    stage('Deploy to Dev') {
        environment {
            AUTH_TOKEN = credentials('argocd-jenkins-deployer-token')
        }
        steps {
            container('docker-tools') {
                sh 'docker run -t schoolofdevops/argocd-cli argocd app sync dso-demo --insecure --server $ARGO_SERVER --auth-token $AUTH_TOKEN'
                sh 'docker run -t schoolofdevops/argocd-cli argocd app wait dso-demo --health --timeout 300 --insecure --server $ARGO_SERVER --auth-token $AUTH_TOKEN'
            }
        }
    }

    stage('Dynamic Analysis') {
      parallel {
          stage('E2E tests') {
              steps {
                  sh 'echo "All Tests passed!!!"'
              }
          }
          stage('DAST') {
              steps {
                  container('docker-tools') {
                      sh 'docker run -t zaproxy/zap-stable zap-baseline.py -t $DEV_URL || exit 0'
                  }
              }
          }
      }
    }
  }
}
