[![Build Status](https://secure.travis-ci.org/tallakt/spliner.png?branch=master)](http://travis-ci.org/tallakt/spliner)

Spliner
=======

Spliner is a Ruby library to perform cubic spline interpolation
based on provided key points (X1, Y1), (X2, Y2), ... , (Xn,Yn)

It also supports extrapolation outside the provided range of X
values.

Installation
------------

Spliner requires Ruby 1.9 or later. Install with rubygems:

    gem install spliner

Quick Start
-----------

    require 'spliner'

    # Initialize a spline interpolation with x range 0.0..2.0
    my_spline = Spliner::Spliner.new [0.0, 1.0, 2.0], [0.0, 1.0, 2.0]

    # Interpolate for a single value
    y1 = my_spline[0.5]

    # Perform interpolation on 11 values ranging from 0..2.0
    y_values = my_spline[(0.0..2.0).step(0.1)]

    # You may prefer to use the shortcut class method
    y2 = Spliner::Spliner[[0.0, 1.0, 2.0], [0.0, 1.0, 0.5], 0.5]

    # perform extrapolation outside key points using linear Y = aX + b
    ex_spline = Spliner::Spliner.new [0.0, 1.0, 2.0], [0.0, 1.0, 2.0], :extrapolate => '10%'
    xx = ex_spline[2.1] # returns 0.4124999999999999

    # perform extrapolation outside key points using linear Y = aX + b
    ex_spline = Spliner::Spliner.new [0.0, 1.0, 2.0], [0.0, 1.0, 2.0], :extrapolate => '10%', :emethod => :hold)
    xx = ex_spline[2.1] # returns 0.5

    # Alternative intialization using Hash
    ar_spline = Spliner::Spliner.new({1.0 => 0.0, 2.0 => 3.0, 3.0 => 1.0})

    # When duplicate X values are encountered, two or more discontinuous curves are used
    two_spline = Spliner::Spliner.new [1.0, 2.0, 2.0, 3.0], [0.0, 3.0, 0.0, 1.0]
    puts two_spline.sections # prints 2
    

Spliner is based on the interpolation described on this page
http://en.wikipedia.org/wiki/Spline_interpolation
 

Contributing to Spliner
--------------------------

Feel free to fork the project on GitHub and send fork requests. Please 
try to have each feature separated in commits.


Home page
---------

http://www.github.com/tallakt/spliner

http://rubygems.org/gems/spliner

License
-------

    (The MIT License)

    Copyright (C) 2012 Tallak Tveide

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



