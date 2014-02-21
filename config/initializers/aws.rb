require 'aws/s3'

AWS::S3::Base.establish_connection!(
  :access_key_id => ENV['JJ_S3_ACCESS_KEY'],
  :secret_access_key => ENV['JJ_S3_SECRET_ACCESS_KEY']
)