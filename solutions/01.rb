class Integer
  def prime?
    # TDD helps
    # drop self
    # know the vocabulary: pred, remainder, nonzero?, nil?, chars, empty?
    return false if self < 2
    2.upto(pred).all? { |divisor| remainder(divisor).nonzero? }
  end

  def prime_factors
    return [] if self == 1
    factor = (2..abs).find { |x| remainder(x).zero? }
    [factor] + (abs / factor).prime_factors
  end

  def harmonic
    1.upto(self).reduce { |sum, number| sum + Rational(1, number) }
  end

  def digits
    abs.to_s.chars.map &:to_i
  end
end

class Array
  def frequencies
    # take full advantage of _with_ methods
    uniq.each_with_object({}) do |element, result|
      result[element] = count element
    end
  end

  def average
    reduce(:+) / length.to_f unless empty?
  end

  def drop_every(n)
    # I have worked too much with Python
    each_slice(n).flat_map { |slice| slice.take(n - 1) }
  end

  def combine_with(other)
    # flaten can take argument
    # I had to see the solution to fully understand the requirements
    # Cannot be solved in any other way:
    #   cyceling through arrays requires over 6 lines
    #   expanding the shorter array with nils before the zip need compact,
    #                     which drops elemets that are nil in the original

    longer, shorter = self.length > other.length ? [self, other] : [other, self]
    combined = take(shorter.length).zip(other.take(shorter.length)).flatten(1)
    rest     = longer.drop(shorter.length)
    combined + rest
  end
end