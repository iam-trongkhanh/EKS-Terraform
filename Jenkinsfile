pipeline {
    agent any

    options {
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
        // Prevent multiple pipeline runs modifying the same infrastructure
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        choice(
            name: 'ENV',
            choices: ['dev', 'staging'],
            description: 'Target environment (production requires explicit pipeline change)'
        )
        
        booleanParam(
            name: 'RUN_TF_VALIDATE',
            defaultValue: true,
            description: 'Run terraform validate'
        )
        
        booleanParam(
            name: 'RUN_TF_LINT',
            defaultValue: true,
            description: 'Run terraform lint (tflint)'
        )
        
        booleanParam(
            name: 'RUN_TF_SECURITY',
            defaultValue: true,
            description: 'Run terraform security scan (tfsec)'
        )
        
        booleanParam(
            name: 'RUN_PLAN',
            defaultValue: true,
            description: 'Run terraform plan'
        )
        
        booleanParam(
            name: 'RUN_APPLY',
            defaultValue: false,
            description: 'Run terraform apply (REQUIRES MANUAL APPROVAL)'
        )
    }

    environment {
        AWS_REGION = ''
        TF_STATE_BUCKET = ''
        TF_LOCK_TABLE = ''

        TF_WORKSPACE = "${params.ENV}"
        
        TF_STATE_KEY = "${params.ENV}/eks/terraform.tfstate"
        
        TF_VERSION = '1.5.0'
        
        TFSEC_EXIT_CODE = '1'
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out repository..."
                    checkout scm
                    echo "Repository checked out successfully"
                    sh 'git rev-parse HEAD > .git/commit-hash'
                    sh 'cat .git/commit-hash'
                }
            }
        }

        stage('Prepare Environment') {
            steps {
                script {
                    echo "Preparing environment for ${params.ENV}"
                    sh '''
                        echo "Checking Terraform installation..."
                        terraform version || (echo "ERROR: Terraform not found" && exit 1)
                        
                        echo "Checking AWS CLI installation..."
                        aws --version || (echo "ERROR: AWS CLI not found" && exit 1)
                        
                        echo "Checking kubectl installation (if needed)..."
                        kubectl version --client || echo "WARNING: kubectl not found (may be optional)"
                    '''
                    
                    sh 'rm -rf .terraform terraform.tfplan terraform.tfplan.json || true'
                    
                    echo "Environment prepared for ${params.ENV}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    echo "Initializing Terraform for environment: ${params.ENV}"

                    withCredentials([
                        aws(credentialsId: '', region: "${env.AWS_REGION}")
                    ]) {
                        sh '''
                            terraform init \
                                -backend-config="bucket=${TF_STATE_BUCKET}" \
                                -backend-config="key=${TF_STATE_KEY}" \
                                -backend-config="region=${AWS_REGION}" \
                                -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
                                -backend-config="encrypt=true" \
                                -reconfigure \
                                -input=false
                            
                            terraform workspace select ${TF_WORKSPACE} || terraform workspace new ${TF_WORKSPACE}
                            terraform workspace show
                        '''
                    }
                    
                    echo "Terraform initialized successfully"
                }
            }
        }

        stage('Terraform Validate') {
            when {
                expression { params.RUN_TF_VALIDATE == true }
            }
            steps {
                script {
                    echo "Validating Terraform configuration..."

                    withCredentials([
                        aws(credentialsId: '', region: "${env.AWS_REGION}")
                    ]) {
                        sh '''
                            terraform validate
                        '''
                    }
                    
                    echo "Terraform validation passed"
                }
            }
        }

        stage('Terraform Lint') {
            when {
                expression { params.RUN_TF_LINT == true }
            }
            steps {
                script {
                    echo "Running Terraform lint (tflint)..."
                    sh '''
                        if command -v tflint &> /dev/null; then
                            tflint --init || true
                            tflint --format=default || echo "WARNING: tflint found issues (non-blocking)"
                        else
                            echo "WARNING: tflint not installed, skipping lint stage"
                        fi
                    '''
                }
            }
        }

        stage('Terraform Security Scan') {
            when {
                expression { params.RUN_TF_SECURITY == true }
            }
            steps {
                script {
                    echo "Running Terraform security scan (tfsec)..."

                    withCredentials([
                        aws(credentialsId: '', region: "${env.AWS_REGION}")
                    ]) {
                        sh '''
                            if ! command -v tfsec &> /dev/null; then
                                echo "Installing tfsec..."
                                echo "ERROR: tfsec not installed and auto-install not configured"
                                exit 1
                            fi
                            
                            tfsec . --format=json --out=tfsec-report.json || true
                            tfsec . --format=default --out=tfsec-report.txt || true
                            
                            if [ -f tfsec-report.json ]; then
                                echo "Security scan completed. Review reports."
                            fi
                        '''
                    }
                    
                    // Archive security reports
                    archiveArtifacts artifacts: 'tfsec-report.*', allowEmptyArchive: true
                    
                    echo "Security scan completed"
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.RUN_PLAN == true }
            }
            steps {
                script {
                    echo "Running Terraform plan for environment: ${params.ENV}"

                    withCredentials([
                        aws(credentialsId: '', region: "${env.AWS_REGION}")
                    ]) {
                        sh """
                            terraform plan \
                                -var="environment=${params.ENV}" \
                                -var="aws_region=${env.AWS_REGION}" \
                                -out=terraform.tfplan \
                                -detailed-exitcode
                            
                            PLAN_EXIT_CODE=$?
                            
                            if [ \$PLAN_EXIT_CODE -eq 0 ]; then
                                echo "No changes detected"
                            elif [ \$PLAN_EXIT_CODE -eq 2 ]; then
                                echo "Changes detected - plan file created"
                            else
                                echo "ERROR: Terraform plan failed"
                                exit 1
                            fi
                        """
                    }
                    
                    sh 'terraform show -json terraform.tfplan > terraform.tfplan.json || true'
                    
                    archiveArtifacts artifacts: 'terraform.tfplan,terraform.tfplan.json', allowEmptyArchive: false
                    
                    sh '''
                        echo "=== Terraform Plan Summary ==="
                        terraform show terraform.tfplan | head -100
                    '''
                    
                    echo "Terraform plan completed"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.RUN_APPLY == true }
            }
            steps {
                script {
                    echo "=== TERRAFORM APPLY STAGE ==="
                    echo "This will MODIFY infrastructure in environment: ${params.ENV}"
                    echo "Manual approval required before proceeding"
                    
                    input(
                        id: 'terraform-apply-approval',
                        message: "Approve Terraform Apply for ${params.ENV}?",
                        ok: 'Apply',
                        parameters: [
                            text(
                                name: 'approver_name',
                                description: 'Your name (for audit trail)',
                                defaultValue: ''
                            ),
                            text(
                                name: 'reason',
                                description: 'Reason for applying changes',
                                defaultValue: ''
                            )
                        ]
                    )
                    
                    echo "Apply approved. Proceeding with terraform apply..."
                    
                    script {
                        if (!fileExists('terraform.tfplan')) {
                            error("Plan file not found. Cannot proceed with apply. Run plan stage first.")
                        }
                    }
                    
                    withCredentials([
                        aws(credentialsId: '', region: "${env.AWS_REGION}")
                    ]) {
                        sh '''
                            terraform apply \
                                -auto-approve \
                                terraform.tfplan
                            
                            echo "Terraform apply completed successfully"
                        '''
                    }
                    
                    echo "Infrastructure changes applied to ${params.ENV}"
                }
            }
        }

        stage('Notify') {
            steps {
                script {
                    echo "Preparing notifications..."

                    def buildStatus = currentBuild.result ?: 'SUCCESS'
                    def envName = params.ENV
                    def buildUrl = env.BUILD_URL
                    
                    echo "Notification step placeholder"
                }
            }
        }
    }

    post {
        success {
            script {
                echo "Pipeline completed successfully for ${params.ENV}"
                // Cleanup plan files after successful apply (optional)
                if (params.RUN_APPLY && params.RUN_APPLY == true) {
                    sh 'rm -f terraform.tfplan terraform.tfplan.json || true'
                }
            }
        }
        
        failure {
            script {
                echo "Pipeline failed for ${params.ENV}"
                echo "Review logs and fix issues before retrying"
            }
        }
        
        always {
            script {
                echo "Cleaning up workspace..."
                // Keep plan files for investigation on failure
                if (currentBuild.result == 'FAILURE') {
                    echo "Plan files retained for investigation"
                }
                
                // Archive logs
                archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
                
                // Cleanup sensitive files (safety measure)
                sh 'rm -f *.tfvars || true'
                sh 'rm -f .terraform.tfstate.lock.info || true'
            }
        }
    }
}

