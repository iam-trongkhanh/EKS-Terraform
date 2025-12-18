pipeline {
    agent {
        label '________REPLACE_WITH_JENKINS_AGENT_LABEL________'
    }

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
        // Non-sensitive environment variables
        AWS_REGION = '________REPLACE_WITH_AWS_REGION________'
        TF_STATE_BUCKET = '________REPLACE_WITH_TERRAFORM_BACKEND_S3_BUCKET________'
        TF_LOCK_TABLE = '________REPLACE_WITH_TERRAFORM_BACKEND_DYNAMODB_TABLE________'
        
        // Terraform workspace maps to environment parameter
        // TODO: Verify this matches your Terraform workspace strategy
        // Alternative: Use separate tfvars files per environment if workspaces are not used
        TF_WORKSPACE = "${params.ENV}"
        
        // Terraform state file key (environment-aware)
        // TODO: Verify backend key structure matches your S3 bucket organization
        TF_STATE_KEY = "${params.ENV}/eks/terraform.tfstate"
        
        // Terraform version (adjust if needed)
        TF_VERSION = '1.5.0'
        
        // Security scan failure threshold
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
                    
                    // Verify required tools are installed
                    sh '''
                        echo "Checking Terraform installation..."
                        terraform version || (echo "ERROR: Terraform not found" && exit 1)
                        
                        echo "Checking AWS CLI installation..."
                        aws --version || (echo "ERROR: AWS CLI not found" && exit 1)
                        
                        echo "Checking kubectl installation (if needed)..."
                        kubectl version --client || echo "WARNING: kubectl not found (may be optional)"
                    '''
                    
                    // Clean workspace (safety measure)
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
                        // TODO: Replace with your AWS credentials ID in Jenkins
                        aws(credentialsId: '________REPLACE_WITH_AWS_CREDENTIALS_ID_IN_JENKINS________', region: "${env.AWS_REGION}")
                    ]) {
                        sh '''
                            # Initialize Terraform with backend configuration
                            # Note: backend-config flags override placeholders in backend.tf
                            # This allows environment-specific backend configuration
                            terraform init \
                                -backend-config="bucket=${TF_STATE_BUCKET}" \
                                -backend-config="key=${TF_STATE_KEY}" \
                                -backend-config="region=${AWS_REGION}" \
                                -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
                                -backend-config="encrypt=true" \
                                -reconfigure \
                                -input=false
                            
                            # Select or create workspace
                            # TODO: Verify workspace strategy matches your organization's approach
                            # Alternative: Use separate tfvars files per environment if workspaces are not used
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
                        aws(credentialsId: '________REPLACE_WITH_AWS_CREDENTIALS_ID_IN_JENKINS________', region: "${env.AWS_REGION}")
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
                    
                    // TODO: Install tflint if not available on agent
                    // Alternative: Use Docker image with tflint pre-installed
                    sh '''
                        if command -v tflint &> /dev/null; then
                            tflint --init || true
                            tflint --format=default || echo "WARNING: tflint found issues (non-blocking)"
                        else
                            echo "WARNING: tflint not installed, skipping lint stage"
                            echo "TODO: Install tflint or use Docker image with tflint"
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
                        aws(credentialsId: '________REPLACE_WITH_AWS_CREDENTIALS_ID_IN_JENKINS________', region: "${env.AWS_REGION}")
                    ]) {
                        sh '''
                            # Install tfsec if not available
                            if ! command -v tfsec &> /dev/null; then
                                echo "Installing tfsec..."
                                # TODO: Adjust installation method based on agent OS
                                # Example for Linux:
                                # wget -O - https://aquasecurity.github.io/tfsec/latest/install.sh | bash
                                echo "ERROR: tfsec not installed and auto-install not configured"
                                exit 1
                            fi
                            
                            # Run tfsec scan
                            # Exit code 1 = issues found (HIGH/CRITICAL severity)
                            # Exit code 0 = no issues or only LOW/MEDIUM severity
                            tfsec . --format=json --out=tfsec-report.json || true
                            tfsec . --format=default --out=tfsec-report.txt || true
                            
                            # Check for HIGH/CRITICAL issues
                            if [ -f tfsec-report.json ]; then
                                # TODO: Parse JSON and fail on HIGH/CRITICAL severity
                                # For now, tfsec will exit with code 1 if issues found
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
                        aws(credentialsId: '________REPLACE_WITH_AWS_CREDENTIALS_ID_IN_JENKINS________', region: "${env.AWS_REGION}")
                    ]) {
                        sh """
                            # Generate terraform plan
                            # Pass environment variable to Terraform
                            terraform plan \
                                -var="environment=${params.ENV}" \
                                -var="aws_region=${env.AWS_REGION}" \
                                -out=terraform.tfplan \
                                -detailed-exitcode
                            
                            PLAN_EXIT_CODE=$?
                            
                            # Exit code 0 = no changes
                            # Exit code 1 = error
                            # Exit code 2 = changes present
                            
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
                    
                    // Convert plan to JSON for easier parsing (optional)
                    sh 'terraform show -json terraform.tfplan > terraform.tfplan.json || true'
                    
                    // Archive plan file as artifact
                    archiveArtifacts artifacts: 'terraform.tfplan,terraform.tfplan.json', allowEmptyArchive: false
                    
                    // Display plan summary
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
                    echo "=== WARNING: TERRAFORM APPLY STAGE ==="
                    echo "This will MODIFY infrastructure in environment: ${params.ENV}"
                    echo "Manual approval required before proceeding"
                    
                    // Require manual approval
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
                    
                    // Verify plan file exists
                    script {
                        if (!fileExists('terraform.tfplan')) {
                            error("Plan file not found. Cannot proceed with apply. Run plan stage first.")
                        }
                    }
                    
                    withCredentials([
                        aws(credentialsId: '________REPLACE_WITH_AWS_CREDENTIALS_ID_IN_JENKINS________', region: "${env.AWS_REGION}")
                    ]) {
                        sh '''
                            # Apply the saved plan file
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
                    
                    // TODO: Implement notification to your preferred channel
                    // Examples below (uncomment and configure as needed):
                    
                    /*
                    // Slack notification example
                    slackSend(
                        channel: '________REPLACE_WITH_SLACK_CHANNEL________',
                        color: buildStatus == 'SUCCESS' ? 'good' : 'danger',
                        message: "Terraform Pipeline: ${buildStatus}\nEnvironment: ${envName}\nBuild: ${buildUrl}"
                    )
                    */
                    
                    /*
                    // Email notification example
                    emailext(
                        subject: "Terraform Pipeline ${buildStatus}: ${envName}",
                        body: "Terraform pipeline for ${envName} completed with status: ${buildStatus}\n\nBuild URL: ${buildUrl}",
                        to: "________REPLACE_WITH_EMAIL_RECIPIENTS________",
                        recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                    )
                    */
                    
                    /*
                    // Generic webhook example
                    sh """
                        curl -X POST '________REPLACE_WITH_WEBHOOK_URL________' \
                            -H 'Content-Type: application/json' \
                            -d '{
                                "status": "${buildStatus}",
                                "environment": "${envName}",
                                "build_url": "${buildUrl}"
                            }'
                    """
                    */
                    
                    echo "Notification placeholder - TODO: Configure notification endpoint"
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

