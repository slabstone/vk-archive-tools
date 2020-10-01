# VK Archive Tools

`download-attachments.rb` downloads all images in specified chat

## Installation

    $ sudo apt install ruby bundler
    $ bundle install
    
You may need to install `zlib1g-dev` for `nokogiri`:

    $ sudo apt install zlib1g-dev
    
## Usage

    $ download-attachments.rb <peer-id>
    
Archive root dir is expected at `./Archive`, images are downloaded to `./download/<peer-id>/`.

Use `socksify_ruby` to download via Tor.

Tested on Ubuntu 20.04 WSL.

## Limitations

Very old images (`x_<...>.jpg`) will be downloaded in web resolution (max 604px).

## TODO

* add command line argument for archive path
* handle old images
