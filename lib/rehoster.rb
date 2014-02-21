class Rehoster
  require 'aws/s3'
  
  BUCKET = "jimbojeopardy-images"
  MIME_TYPES = {
    "jpg"  => "image/jpeg",
    "png"  => "image/png",
    "jpeg" => "image/jpeg",
    "mp3"  => "audio/mpeg",
    "mp4"  => "video/mp4",
    "wmv"  => "video/x-ms-wmv",
    "mov"  => "video/quicktime",
    "flv"  => "video/x-flv"
  }
  
  class << self
    def s3_options(s3_filename)
      # TODO: find out what's happening with all their broken images
      {
        :content_type => MIME_TYPES[extension_for(s3_filename)],
        :access => :public_read,
        :cache_control => "public; max-age=#{365.days}"
      }
    end
    
    def rehost(url)
      uri = URI.parse(url)
      s3_filename = uri.path.split("/").last
      
      data = Net::HTTP.start(uri.host, uri.port) do |http|
        return unless http.head(uri.path).code == '200'
        
        http.get(uri.path).body
      end
      
      return unless data
      
      response = AWS::S3::S3Object.store(s3_filename, data, BUCKET, s3_options(s3_filename))
      
      "https://s3.amazonaws.com/#{BUCKET}/#{s3_filename}" if response.code == 200
    end
    
    def extension_for(filename)
      filename.split(".").last
    end
  end
end