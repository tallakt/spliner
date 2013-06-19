require 'matrix'
require 'spliner/spliner_section'

module Spliner

  # Spliner::SplinerSection is only used via Spliner::Spliner
  #
  # As the spline algorithm does not handle duplicate X values well, the 
  # curve is split into two non continuous parts where duplicate X values 
  # appear. Each such part is represented by a SplinerSection
  class SplinerSection
    attr_reader :k, :x, :y

    def initialize(x, y)
      @x, @y = x, y
      @x_pairs = @x.each_cons(2).map {|pair| pair.first..pair.last }
      check_points_increasing
      calculate_a_k
    end

    def range
      @x.first..@x.last
    end

    def calculate_a_k
      if @x.size > 1
        inv_diff = @x.each_cons(2).map {|x1, x2| 1.0 / (x2 - x1) }
        a_diag = 2.0 * Matrix::diagonal(*vector_helper(inv_diff))
        a_non_diag = Matrix::build(@x.size) do |row, col|
          if row == col + 1
            inv_diff[col]
          elsif col == row + 1
            inv_diff[row]
          else
            0.0
          end
        end

        a = a_diag + a_non_diag

        tmp = @x.zip(@y).each_cons(2).map do |p1, p2|
          x1, y1 = p1
          x2, y2 = p2
          delta_x = (x2 - x1)
          3.0 * (y2 - y1) / (delta_x * delta_x)
        end
        b = vector_helper(tmp)

        if RUBY_VERSION < "1.9.3"
          @k = a.inv * b
        else
          @k = a.lup_decomposition.solve b
        end
      else
        @k = Vector[0.0]
      end
    end
    private :calculate_a_k

    # returns an interpolated value
    def get(v)
      i = @x_pairs.find_index {|pair| pair.cover? v }
      if i
        x_pair = @x_pairs[i]
        x_min = x_pair.min
        dx = x_pair.max - x_min
        y_max = @y[i + 1]
        y_min = @y[i]
        dy = y_max - y_min
        t = (v - x_min) / dx
        a =      @k[i] * dx - dy
        b = -@k[i + 1] * dx + dy
        one_minus_t = 1 - t
        t * y_max + one_minus_t * ( y_min + t * ( a * one_minus_t + b * t ) )
      elsif @x.size == 1 && @x.first == v
        @y.first
      else
        nil
      end
    end

    # for a vector [a, b, c] returns [a, a + b, b + c, c]
    def vector_helper(a)
      Vector[*([0.0] + a)] + Vector[*(a + [0.0])]
    end
    private :vector_helper

    def check_points_increasing
      @x.each_cons(2) do |x1, x2|
        raise 'Key point\'s X values should be in increasing order' unless x2 > x1
      end
    end
    private :check_points_increasing
  end
end

