require 'matrix'
require 'spliner/spliner_section'

module Spliner
  # Spliner::Spliner provides cubic spline interpolation based on provided 
  # key points on a X-Y curve.
  #
  # == Example
  #
  #    require 'spliner'
  #    
  #    # Initialize a spline interpolation with x range 0.0..2.0
  #    my_spline = Spliner::Spliner.new [0.0, 1.0, 2.0], [0.0, 1.0, 0.5]
  #    
  #    # Interpolate for a single value
  #    y1 = my_spline[0.5]
  #    
  #    # Perform interpolation on 11 values ranging from 0..2.0
  #    y_values = my_spline[(0.0..2.0).step(0.1)]
  #
  #    # You may prefer to use the shortcut class method
  #    y2 = Spliner::Spliner[[0.0, 1.0, 2.0], [0.0, 1.0, 0.5], 0.5]
  #
  #
  # Algorithm based on http://en.wikipedia.org/wiki/Spline_interpolation
  #
  class Spliner
    attr_reader :range

    # Creates a new Spliner::Spliner object to interpolate between
    # the supplied key points. 
    #
    # The key points shoul be in increaing X order. When duplicate X 
    # values are encountered, the spline is split into two or more 
    # discontinuous sections.
    #
    # The extrapolation method may be :linear by default, using a linear 
    # extrapolation at the curve ends using the curve derivative at the 
    # end points. The :hold method will use the Y value at the nearest end 
    # point of the curve.
    #
    # @overload initialize(key_points, options)
    #   @param key_points [Hash{Float => Float}] keys are X values in increasing order, values Y
    #   @param options [Hash]
    #   @option options [Range,String] :extrapolate ('0%') either a range or percentage, eg '10.0%', or float 0.1
    #   @option options [Symbol] :emethod (:linear) extrapolation method
    #   @option options [Symbol] :fix_invalid_x (false) delete data points not in increasing order
    #
    # @overload initialize(x, y, options)
    #   @param x [Array(Float),Vector] the X values of the key points
    #   @param y [Array(Float),Vector] the Y values of the key points
    #   @param options [Hash]
    #   @option options [Range,String] :extrapolate ('0%') either a range or percentage, eg '10.0%', or float 0.1
    #   @option options [Symbol] :emethod (:linear) extrapolation method
    #   @option options [Symbol] :fix_invalid_x (false) delete data points not in increasing order
    #
    def initialize(*param)
      # sort parameters from two alternative initializer signatures
      x, y = nil
      case param.first
      when Array, Vector
        xx,yy, options = param
        x = xx.to_a
        y = yy.to_a
      else
        points, options = param
        x = points.keys
        y = points.values
      end
      options ||= {}

      if options[:fix_invalid_x]
        begin
          size_at_start = x.size
          pp = Hash[x.zip y]
          to_delete = pp.keys.each_cons(2).select {|a,b| b < a}.map(&:last)
          to_delete.each {|k| pp.delete k }
          x = pp.keys
          y = pp.values
        end while x.size < size_at_start
      end

      @sections = split_at_duplicates(x).map {|slice| SplinerSection.new x[slice], y[slice] }

      # Handle extrapolation option parameter
      options[:extrapolate].tap do |ex|
        case ex
        when /^\d+(\.\d+)?\s?%$/
          percentage = ex[/\d+(\.\d+)?/].to_f
          span = x.last - x.first
          extra = span * percentage * 0.01
          @range = (x.first - extra)..(x.last + extra)
        when Range
          @range = ex
        when Float
          span = x.last - x.first
          extra = span * ex
          @range = (x.first - extra)..(x.last + extra)
        when nil
          @range = x.first..x.last
        else
          raise 'Unable to use extrapolation parameter'
        end
      end
      @extrapolation_method = options[:emethod] || :linear
    end

    # shortcut method to instanciate a Spliner::Spliner object and
    # return a series of interpolated values. Options are like 
    # Spliner::Spliner#initialize
    #
    # @overload interpolate(points, x, options)
    #   @param points [Hash{Float => Float}] keys are X values in increasing order, values Y
    #   @param x [Float,Vector,Enumerable(Float)] X value(s) to interpolate on
    #   @param options [Hash]
    #
    # @overload interpolate(key_x, key_y, x, options)
    #   @param key_x [Array(Float),Vector] the X values of the key points
    #   @param_key_y [Array(Float),Vector] the Y values of the key points
    #   @param x [Float,Vector,Enumerable(Float)] X value(s) to interpolate on
    #   @param options [Hash]
    #
    def self.interpolate(*args)
      if (args.first.class == Hash)
        key_points, x, options = args
        s = Spliner.new key_points, (options || {})
        s[x]
      else
        key_x, key_y, x, options = args
        s = Spliner.new key_x, key_y, (options || {})
        s[x]
      end
    end

    class << self
      alias :'[]' :interpolate
    end

    # returns the ranges at each slice between duplicate X values
    def split_at_duplicates(x)
      # find all indices with duplicate x values
      dups = x.each_cons(2).map{|a,b| a== b}.each_with_index.select {|b,i| b }.map {|b,i| i}
      ([-1] + dups + [x.size - 1]).each_cons(2).map {|end0, end1| (end0 + 1)..end1 }
    end
    private :split_at_duplicates


    # returns the interpolated Y value(s) at the specified X
    #
    # @param x [Float,Vector,Enumerable(Float)] x
    #
    # == Example
    #
    #    my_spline = Spliner::Spliner.new [0.0, 1.0, 2.0], [0.0, 1.0, 0.5]
    #    # get one value
    #    y1 = my_spline.get 0.5
    #    # get many values
    #    y2 = my_spline.get [0.5, 1.5, 2.5]
    #    y3 = my_spline.get 0.5, 1.5, 2.5
    #    # get a range of values
    #    y4 = my_spline.get 1..3
    #    # generate an enumeration of x values
    #    y5 = my_spline.get (1.5..2.5).step(0.5)
    #
    def get(*x)
      xx = if x.size == 1
             x.first
           else
             x
           end

      get_func = lambda do |v|
        i = @sections.find_index {|section| section.range.cover? v }
        if i
          @sections[i].get v
        elsif range.cover? v
          extrapolate(v)
        else
          nil
        end
      end

      case xx
      when Vector
         xx.collect {|x| get_func.call(x) }
      when Enumerable
        xx.map {|x| get_func.call(x) }
      else
        get_func.call(xx)
      end
    end

    alias :'[]' :get 

    # The number of non-continuous sections used
    def sections
      @sections.size
    end



    def extrapolate(v)
      x, y, k = if v < first_x
                  [@sections.first.x.first, @sections.first.y.first, @sections.first.k.first]
                else
                  [@sections.last.x.last, @sections.last.y.last, @sections.last.k[-1]]
                end

      case @extrapolation_method
      when :hold
        y
      else
        y + k * (v - x)
      end
    end
    private :extrapolate

    def first_x
      @sections.first.x.first
    end
    private :first_x
  end
end

