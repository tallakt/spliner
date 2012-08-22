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
  #
  #    require 'spliner'
  #    # Initialize a spline interpolation with x range 0.0..2.0
  #    my_spline = Spliner::Spliner.new [0.0, 1.0, 2.0], [0.0, 1.0, 0.5]
  #    # Perform interpolation on 31 values ranging from 0..2.0
  #    x_values = (0..30).map {|x| x / 30.0 * 2.0 }
  #    y_values = x_values.map {|x| my_spline[x] }
  #
  # Algorithm based on http://en.wikipedia.org/wiki/Spline_interpolation
  #
  class Spliner
    attr_reader :range

    # Creates a new Spliner::Spliner object to interpolate between
    # the supplied key points. 
    #
    # The key points should be increasing and not contain duplicate X values.
    # At least two points must be provided.
    #
    # The extrapolation method may be :linear by default, using a linear 
    # extrapolation at the curve ends using the curve derivative at the 
    # end points. The :hold method will use the Y value at the nearest end 
    # point of the curve.
    #
    # @overload initialize(key_points, options)
    #   @param key_points [Hash{Float => Float}] keys are X values in increasing order, values Y
    #   @param options [Hash]
    #   @option options [Range,String] :extrapolate ('0%') either a range or percentage, eg '10.0%'
    #   @option options [Symbol] :emethod (:linear) extrapolation method
    #
    # @overload initialize(x, y, options)
    #   @param x [Array(Float),Vector] the X values of the key points
    #   @param y [Array(Float),Vector] the Y values of the key points
    #   @param options [Hash]
    #   @option options [Range,String] :extrapolate ('0%') either a range or percentage, eg '10.0%'
    #   @option options [Symbol] :emethod (:linear) extrapolation method
    #
    def initialize(*param)
      # sort parameters from two alternative initializer signatures
      case param.first
      when Array, Vector
        xx,yy, options = param
        @x = xx.to_a
        @y = yy.to_a
        @points = Hash[@x.zip @y]
      else
        @points, options = param
        @x = @points.keys
        @y = @points.values
      end
      options ||= {}
      @x_pairs = @x.each_cons(2).map {|pair| pair.first..pair.last }

      check_points_increasing
      raise 'Interpolation needs at least two points' unless @points.size >= 2


      # Handle extrapolation option parameter
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

      calculate_a_k
    end

    def calculate_a_k
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
    end
    private :calculate_a_k

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
    def vector_helper(a)
      Vector[*([0.0] + a)] + Vector[*(a + [0.0])]
    end
    private :vector_helper



    def check_points_increasing
      @x.each_cons(2) do |x1, x2|
        raise 'Points must form a series of x and y values where x is increasing' unless x2 > x1
      end
    end
    private :check_points_increasing

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
