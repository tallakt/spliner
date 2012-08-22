require 'spliner'

describe Spliner::Spliner do
  DATASET = {0.0 => 0.0, 1.0 => 1.0, 2.0 => 0.5}
  KEYS_0_100 = {0.0 => 0.0, 100.0 => 100.0}


  it 'should not accept x values that are not increasing' do
    expect(lambda { Spliner::Spliner.new [0.0, -1.0], [0.0, 1.0] }).to raise_exception
  end

  it 'should support key points with a single value' do
    s1 = Spliner::Spliner.new Hash[0.0, 0.0]
    expect(s1.get 0.0).to be_within(0.0001).of(0.0)
    expect(s1.get 1.5).to be_nil

    s2 = Spliner::Spliner.new Hash[0.0, 0.0], :extrapolate => -1..1
    expect(s2.get 0.0).to be_within(0.0001).of(0.0)
    expect(s2.get 0.5).to be_within(0.0001).of(0.0)
  end

  it 'supports the Hash initializer' do
    s1 = Spliner::Spliner.new Hash[0.0, 0.0, 1.0, 1.0]
    expect(s1[0.5]).to be_within(0.0001).of(0.5)

    s2 = Spliner::Spliner.new Hash[0.0, 0.0, 1.0, 1.0], :extrapolate => '100%'
    expect(s2[0.5]).to be_within(0.0001).of(0.5)
    expect(s2.range.first).to be_within(0.0001).of(-1.0)
  end

  it 'supports the x-y array/vector initializer' do
    s1 = Spliner::Spliner.new [0.0, 1.0], [0.0, 1.0]
    expect(s1[0.5]).to be_within(0.0001).of(0.5)

    s2= Spliner::Spliner.new [0.0, 1.0], [0.0, 1.0], :extrapolate => '100%'
    expect(s2[0.5]).to be_within(0.0001).of(0.5)
    expect(s2.range.first).to be_within(0.0001).of(-1.0)

    s3 = Spliner::Spliner.new Vector[0.0, 1.0], Vector[0.0, 1.0]
    expect(s3[0.5]).to be_within(0.0001).of(0.5)
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

  it 'performs :linear extrapolation outside the data range when such is given' do
    s = Spliner::Spliner.new KEYS_0_100, :extrapolate => -200..200
    expect(s.get -110).not_to be_nil
    expect(s.get -150).to be_within(0.0001).of(-150)
    expect(s.get 150).to be_within(0.0001).of(150)
  end

  it 'performs :hold extrapolation' do
    s = Spliner::Spliner.new KEYS_0_100, :extrapolate => -200..200, :emethod => :hold
    expect(s.get -150).to be_within(0.0001).of(0)
    expect(s.get 150).to be_within(0.0001).of(100)
  end

  it 'supports data ranges given as a string like "10%"' do
    s1 = Spliner::Spliner.new KEYS_0_100, :extrapolate => '10%'
    expect(s1.range.first).to be_within(0.0001).of(-10.0)
    expect(s1.range.last).to be_within(0.0001).of(110.0)

    s2 = Spliner::Spliner.new KEYS_0_100, :extrapolate => '10.0%'
    expect(s2.range.first).to be_within(0.0001).of(-10.0)
    expect(s2.range.last).to be_within(0.0001).of(110.0)

    s3 = Spliner::Spliner.new KEYS_0_100, :extrapolate => '10 %'
    expect(s3.range.first).to be_within(0.0001).of(-10.0)
    expect(s3.range.last).to be_within(0.0001).of(110.0)
  end

  it 'splits data points with duplicate X values into separate sections' do
    s = Spliner::Spliner.new [0.0, 1.0, 1.0, 2.0, 2.0, 3.0], [0.0, 0.0, 1.0, 1.0, 2.0, 2.0], :extrapolate => 3.0..4.0
    expect(s.sections).to eq(3)
    expect(s[-1.0]).to be_nil
    expect(s[0.5]).to be_within(0.0001).of(0.0)
    expect(s[1.5]).to be_within(0.0001).of(1.0)
    expect(s[2.5]).to be_within(0.0001).of(2.0)
    expect(s[3.5]).to be_within(0.0001).of(2.0)
    expect(s[5.0]).to be_nil
  end
end
