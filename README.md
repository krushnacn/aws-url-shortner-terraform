# URL Shortener Project

This project contains a URL shortener service using Node.js AWS Lambda and MySQL on RDS, provisioned via Terraform.

## Structure

- `terraform/` - Terraform configs to provision AWS infra.
- `src/` - Node.js Lambda function code.
- `.github/workflows/ci-cd.yml` - GitHub Actions workflow for CI/CD.

## Setup

1. Create an AWS IAM user with necessary permissions.
2. Configure your AWS CLI or GitHub Secrets with credentials.
3. Set GitHub repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `DB_PASSWORD`
   - `API_KEY`
   - `SUBNET_IDS` (comma-separated list)
   - `DB_SG_ID`

4. Run Terraform commands locally or rely on GitHub Actions to deploy.
5. Create the MySQL table with:

\`\`\`sql
CREATE TABLE urls (
  id INT AUTO_INCREMENT PRIMARY KEY,
  short_id VARCHAR(10) UNIQUE NOT NULL,
  original_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
\`\`\`

## Usage

- Use the `/shorten` POST endpoint with `x-api-key` header to create short URLs.
- Access the short URL path to be redirected.

