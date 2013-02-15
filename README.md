# omilia
A simple TV show tracking web app.


## Dependancies
* Ruby 1.9.3

and the following gems:

* Sinatra
* JSON
* erubis
* bcrypt
* rack-flash
* DataMapper


## Install and Run
To install the dependancies, just run with Ruby 1.9.3:

    % gem install sinatra json erubis bcrypt-ruby rack-flash3 data_mapper

Now download *omilia*:

    % git clone git://github.com/Ps0ke/omilia.git
    % cd omilia/

Next you have to setup the database. I'm going to use SQLite as an example:

On OS X install `sqlite3` via [homebrew](http://mxcl.github.com/homebrew/):

    % brew install sqlite3

Install the necessary DataMapper adapter:

    % gem install dm-sqlite-adapter

And create the database:

    % touch database.db

Now you have to create your `config.rb` file:

```ruby
# database connection
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/database.db")

# set serssion secret
set :session_secret, 'oh so secret!'
```
Details about how DataMapper handles different databases can be be found in its [documentation](http://datamapper.org/getting-started.html).

Finally, yank up the web server and run *omilia*:

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

