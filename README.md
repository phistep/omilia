# omilia
A simple TV show tracking web app.


## Dependancies
* Ruby 1.9.3
* sqlite3
* gems
    * Sinatra
    * JSON
    * erubis
    * bcrypt
    * rack-flash
    * DataMapper
        * dm-sqlite-adapter


## Install and Run
On OS X install `sqlite3` via [homebrew](http://mxcl.github.com/homebrew/):

    % brew install sqlite3

Then just run with Ruby 1.9.3:

    % gem install sinatra json erubis bcrypt-ruby rack-flash3 data_mapper dm-sqlite-adapter

Now download and start *omilia*:

    % git clone git://github.com/Ps0ke/omilia.git
    % cd omilia/
    % touch database.db
    % ruby omilia.rb

Open [http://localhost:4567](http://localhost:4567) in your favorite browser and you're ready to go!


## Powered by
* [Twitter Bootstrap](http://getbootstrap.com/) (included, License: Apache v2.0)
* [jQuery](http://jquery.org/) (included, License: MIT)
* [Sinatra](http://sinatrarb.com) Ruby web framework


## License
[The MIT License](http://opensource.org/licenses/MIT):

> Copyright (c) 2013 Philipp Stephan
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

