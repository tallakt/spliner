require 'spliner'

describe Spliner::Spliner do
  DATASET = {0.0 => 0.0, 1.0 => 1.0, 2.0 => 0.5}

  it 'should not accept x values that are not increasing' do
    expect(lambda { Spliner::Spliner.new({0 => 0, 0 => 10})}).to raise_exception
  end

  it 'should not accept less than two values' do 
    expect(lambda { Spliner::Spliner.new({0 => 0})}).to raise_exception
  end

  it 'should return the data points themselves' do
    s = Spliner::Spliner.new DATASET
    DATASET.each do |k,v|
      expect(s.get(k)).to be_within(0.00001).of(v)
    end
  end

  it 'should return nil outside the data area' do
    s = Spliner::Spliner.new DATASET
    expect(s.get(-1.0)).to be_nil
    expect(s.get(3.0)).to be_nil
  end

  it 'should generate a smooth curve (predefined points)' do
    s = Spliner::Spliner.new DATASET
    expect(s.get(0.4)).to be_within(0.0001).of(0.5260)
    expect(s.get(0.8)).to be_within(0.0001).of(0.9080)
    expect(s.get(1.2)).to be_within(0.0001).of(1.0080)
    expect(s.get(1.6)).to be_within(0.0001).of(0.8260)
  end

  it 'should perform linear interpolation in the case of two data points' do
    s = Spliner::Spliner.new({0 => 0, 10.0 => 100.0})
    expect(s.get(3.0)).to be_within(0.0001).of(30.0)
  end

  it 'supports the [] operator (indexing like)' do
    s = Spliner::Spliner.new DATASET
    expect(s[-1]).to be_nil
    expect(s[0]).to be_within(0.0001).of(0.0)
  end
end
