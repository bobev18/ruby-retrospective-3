class Integer
  def prime?
    (2..self-1).all? { |e| ((self/e) * e) != self }
  end
  def prime_factors
    number, result, divisor = self.abs, [], 1
    while number>1 and divisor+=1
      result << divisor and number /= divisor while number % divisor == 0
      divisor = number-1 if divisor > Math.sqrt(number)
    end
    result
  end
  def harmonic
    1.upto(self).inject { |sum, n| sum + Rational(1, n) }
  end
  def digits
    self.abs.to_s.split('').map { |s| s.to_i }
  end
end
class Array
  def frequencies
    result = {}
    self.map { |e| result[e] = self.count(e) }
    result
  end
  def average
    self.reduce(:+)/self.size.to_f
  end
  def drop_every(n)
    result = []
    self.each_index { |i| result << self[i] if (i+1) % n != 0  }
    result
  end
  def combine_with(other)
    self.zip(other).flatten.select { |e| e != nil }
  end
end