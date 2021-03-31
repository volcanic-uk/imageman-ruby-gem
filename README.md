# Volcanic::Imageman

Ruby gem for Imageman service

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'volcanic-authenticator', git: 'git@github.com:volcanic-uk/Imageman-ruby-gem.git'
```

And then execute:

    $ bundle


## Usage

### Configuration
```ruby
Volcanic::Imageman.configure do |config|
  # Imageman domain url
  config.domain_url = ENV['IMAGEMAN_DOMAIN']
  # Asset image url
  config.asset_image_url = ENV['ASSET_IMAGE_URL']
  # Service name.
  config.service = ENV['APP_NAME']
  # String of authentication key, also accept callable function.
  config.service = ENV['API_KEY'] || -> { SomeMethod.get_api_key }
end
```

### Image
Creating an Image
```ruby
# most of the cases to create an image to Imageman service
# +attachable+ can be type of readable instance such ActionDispatch::Http::UploadedFile. Also support Hash object
# +name+ a string value for the name
# +reference+ can be either a string or Volcanic::Imageman::V1::Reference. Must be unique
# options: 
#  +cache_duration+ an integer for determine the limit of cache time
#  +cacheable+ a boolean of turning on/off the cache. Default true
#  +using_signed_url+ a boolean of forcing request using signed_url. Default is false. But will trigger if file is > 6mb
#  +declared_type+ a string of pre declare the type/extension of the image
image = Volcanic::Imageman::V1::Image.create(attachable: file, name: 'image.jpeg', reference: unique_reference, **opts)
image.inspect # => { :uuid, :reference, :name, :versions, :creator_subject, :cache_duration, :cacheable }

# create using Reference class
reference = ::Reference.new(name: 'image.jpeg', source: 'user-model', **opts)
::Image.create(attachable: file, reference: reference)

# Hash for +attachable+
# for hash +io+ and +filename+ is required, and it always recommended to have the content_type
file = { io: Tempfile.new('image.jpeg'), filename: 'image.jpeg', content_type: 'image/jpeg' }
::Image.create(attachable: file, reference: reference)

# Imageman service are limited to only 6mb image file per request. By that this gem automatically handle
# to use of signed url features to upload the image. You dont have to configure it but if needed to:
::Image.create(attachable: file, reference: reference, using_signed_url: true) # this forcing it eventhough its < 6mb
```

### Reload/Fetch
reload or fetch image details
```ruby
# reload
image = ::Image.create(attachable: file, ...)
image.reload # fetch and update the current instance

# Fetch
# can be either by reference or uuid
image = ::Image.fetch_by(reference: reference, uuid: uuid)
image.inspect # => { :uuid, ...}
```

### Update
update image file or settings
```ruby
#file
image = ::Image.fetch_by(reference: reference, uuid: uuid)
image.update(attachable: file)

# other settings
image.update(cacheable: false, cache_duration: 0)

# class method
# can be either by reference or uuid
::Image.update(attachable: file, reference: reference, uuid: uuid)
```

## Delete
delete an image
```ruby
image = ::Image.fetch_by(reference: reference, uuid: uuid)
image.delete

# or
# can be either by reference or uuid
::Image.delete(reference: reference, uuid: uuid)
```

## check persisted instance
```ruby
image = ::Image.new
image.persisted? # => false

image = ::Image.fetch_by(reference: reference)
image.persisted? # => true

image = ::Image.create(attachable: file, reference: reference)
image.persisted? #=> true
```

## exception

```ruby
::Image.create(attachable: file, reference: reference)
# => raise Volcanic::Imageman::DuplicateImage if duplicates reference
# => raise Volcanic::Imageman::ImageError if validation error

::Image.fetch_by(reference: reference)
# => raise Volcanic::Imageman::ImageNotFound if 404

# => raise Volcanic::Imageman::ServerError if Server Error 500
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/Imageman-ruby-gem.