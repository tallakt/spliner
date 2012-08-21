#
# Spliner::Spliner
#
require 'matrix'

module Spliner
  VERSION = '1.0.1'

  # Spliner::Spliner provides cubic spline interpolation based on provided 
  # key points on a X-Y curve.
  #
  # == Example
  # require 'spliner'
  # # Initialize a spline interpolation with x range 0.0..2.0
  # my_spline = Spliner::Spliner.new({0.0 => 0.0, 1.0 => 1.0, 2.0 => 0.5})
  # # Perform interpolation on 31 values ranging from 0..2.0
  # x_values = (0..30).map {|x| x / 30.0 * 2.0 }
  # y_values = x_values.map {|x| my_spline[x] }
  #
  # http://en.wikipedia.org/wiki/Spline_interpolation
  #
  class Spliner
    attr_reader :range

    # Creates a new Spliner::Spliner object to interpolate between
    # the supplied key points. The key points are provided in a hash where
    # the key is the X value, and the value is the Y value. The X values
    # mush be increasing and not duplicate. You must provide at least 
    # two values.
    #
    # options may take the following keys:
    #
    #   :extrapolate
    #   Specify an area outside the given X values provided that should return
    #   a valid number. The value may be either a range (eg. -10..110) or a
    #   percentage value written as a string (eg '10%'). Default is no
    #   extrapolation.
    #
    #   :emethod
    #   Specify a method of extrapolation, one of :linear (continue curve as 
    #   a straigt line, default), or :hold (use Y values at the curve endpoints)
    #
    def initialize(key_points, options = {})

      @points = key_points
      @x = @points.keys
      @y = @points.values

      check_points_increasing
      raise 'Interpolation needs at least two points' unless @points.size >= 2

      @x_pairs = @points.keys.each_cons(2).map {|pair| pair.first..pair.last }

      inv_diff = @x.each_cons(2).map {|x1, x2| 1 / (x2 - x1) }
      a_diag = 2.0 * Matrix::diagonal(*vector_helper(inv_diff))
      a_non_diag = Matrix::build(@points.size) do |row, col|
        if row == col+ 1
          inv_diff[col]
        elsif col == row + 1
          inv_diff[row]
        else
          0.0
        end
      end

      a = a_diag + a_non_diag

      tmp = @points.each_cons(2).map do |p1, p2|
        x1, y1 = p1
        x2, y2 = p2
        3.0 * (y2 - y1) / (x2 - x1) ** 2.0
      end
      b = vector_helper(tmp)

      @k = a.inv * b

      options[:extrapolate].tap do |ex|
        case ex
        when /^\d+(\.\d+)?\s?%$/
          percentage = ex[/\d+(\.\d+)?/].to_f
          span = @x.last - @x.first
          extra = span * percentage * 0.01
          @range = (@x.first - extra)..(@x.last + extra)
        when Range
          @range = ex
        when nil
          @range = @x.first..@x.last
        else
          raise 'Unable to use extrapolation parameter'
        end
      end

      @extrapolation_method = options[:emethod] || :linear
    end

    # returns an interpolated value
    def get(v)
      i = @x_pairs.find_index {|pair| pair.member? v }
      if i
        dx = @x[i + 1] - @x[i]
        dy = @y[i + 1] - @y[i]
        t = (v - @x[i]) / dx
        a = @k[i] * dx - dy
        b = -(@k[i + 1] * dx - dy)
        (1 - t) * @y[i] + t * @y[i + 1] + t * (1 - t) * (a * (1 - t) + b * t)
      elsif range.member? v
        extrapolate(v)
      else
        nil
      end
    end

    alias :'[]' :get 


    # for a vector [a, b, c] returns [a, a + b, b + c, c]
    # :nodoc:
    def vector_helper(a)
      Vector[*([0.0] + a)] + Vector[*(a + [0.0])]
    end
    private :vector_helper



    # :nodoc:
    def check_points_increasing
      @x.each_cons(2) do |x1, x2|
        raise 'Points must form a series of x and y values where x is increasing' unless x2 > x1
      end
    end
    private :check_points_increasing

    # :nodoc:
    def extrapolate(v)
      case @extrapolation_method
      when :hold
        if v < @x.first
          @y.first
        else
          @y.last
        end
      else
        x, y, k = if v < @x.first
                    [@x.first, @y.first, @k.first]
                  else
                    [@x.last, @y.last, @k[-1]]
                  end
        y + k * (v - x)
      end
    end
    private :extrapolate

  end
end
