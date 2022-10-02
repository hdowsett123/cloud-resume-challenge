<p><strong>AWS Cloud Resume Challenge</strong></p>
<p>This project is a fun challenge to convert your CV/Resume into a static website that is hosted in the cloud with it&apos;s own unique domain name that you can pull up on your pc through the internet.</p>
<p>The 14 steps take you through the actions of setting up the AWS architecture using tools such as CloudFront, S3 buckets, DynamoDB and AWS Lambda, while creating CI/CD pipelines for updates, commits and tests like you would in a working environment.</p>
<p>I have listed the steps and included the visual architecture below for reference...</p>
<img width="761" alt="Screenshot 2022-10-02 at 17 56 44" src="https://user-images.githubusercontent.com/88186800/193460751-88c2d4bf-9212-41ec-ae30-671cd877f4b2.png">
<p><strong>1. HTML</strong></p>
<p>Your Resume/CV needs to be written in HTML. Not a&nbsp;Word doc, not a PDF.</p>
<p><strong>2.CSS</strong></p>
<p>Your resume needs to be styled with CSS. It doesn&rsquo;t have to be fancy, but we need to see something other than raw HTML when we open the webpage.</p>
<p><strong>3. Static Website</strong></p>
<p>Your HTML resume should be deployed online as an Amazon S3 static website.&nbsp;</p>
<p><strong>4. HTTPS</strong></p>
<p>The S3 website URL should use HTTPS for security. You will need to use Amazon CloudFront to help with this.</p>
<p><strong>5.&nbsp;DNS</strong></p>
<p>Point a custom DNS domain name to the CloudFront distribution, so your resume can be accessed at something like my-cool-resume.com. You can use Amazon Route 53 or any other DNS provider for this.&nbsp;</p>
<p><strong>6. Javascript</strong></p>
<p>Your resume webpage should include a visitor counter that displays how many people have accessed the site. You will need to write a bit of Javascript to make this happen.&nbsp;</p>
<p><strong>7. Database</strong></p>
<p>The visitor counter will need to retrieve and update its count in a database somewhere. I suggest you use Amazon&rsquo;s DynamoDB for this.</p>
<p><strong>8. API</strong></p>
<p>Do not communicate directly with DynamoDB from your Javascript code. Instead, you will need to create an API that accepts requests from your web app and communicates with the database. I suggest using AWS&rsquo;s API Gateway and Lambda services for this.&nbsp;</p>
<p><strong>9. Python</strong></p>
<p>You will need to write a bit of code in the Lambda function; you could use more Javascript, but it would be better for our purposes to explore Python &ndash; a common language used in back-end programs and scripts &ndash; and its boto3 library for AWS.</p>
<p><strong>10. Tests</strong></p>
<p>You should also include some tests for your Python code.&nbsp;</p>
<p><strong>11. Infrastructure as Code&nbsp;</strong></p>
<p>You should not be configuring your API resources &ndash; the DynamoDB table, the API Gateway, the Lambda function &ndash; manually, by clicking around in the AWS console. Instead, define them in an infrastructure as code or IaC. It saves you time in the long run.</p>
<p><strong>12. Source Control</strong></p>
<p>You do not want to be updating either your back-end API or your front-end website by making calls from your laptop, though. You want them to update automatically whenever you make a change to the code. Create a GitHub repository for you backend code.</p>
<p><strong>13. CI/CD (Backend)</strong></p>
<p>Set up GitHub Actions such that when you push an update to your IaC template or Python code, your Python tests get run. If the tests pass, the IaC should get packaged and deployed to AWS.</p>
<p><strong>14. CI/CD (Frontend)</strong></p>
<p>Create a second GitHub repository for your website code. Create GitHub Actions such that when you push new website code, the S3 bucket automatically gets updated. (You may need to invalidate your CloudFront cache in the code as well.)</p>
<p>&nbsp;</p>
<p><strong>NOTE</strong>: I no longer have my CV/Resume website up and running through my AWS account, but all the infrastructure and CI/CD is available in the repository.&nbsp;</p>
