require 'spliner'

describe Spliner::Spliner do
  DATASET = {0.0 => 0.0, 1.0 => 1.0, 2.0 => 0.5}
  DATASET_X = [0.0, 1.0, 2.0]
  DATASET_Y = [0.0, 1.0, 0.5]
  KEYS_0_100 = {0.0 => 0.0, 100.0 => 100.0}

  before(:all) do
    epsilon = nil
    e = 1
    while e + 1 > 1
      epsilon = e
      e *= 0.5
    end
    
    @two_epsilon = 2 * epsilon
  end


  it 'should not accept x values that are not increasing' do
    expect(lambda { Spliner::Spliner.new [0.0, -1.0], [0.0, 1.0] }).to raise_exception
  end

  it 'should support key points with a single value' do
    s1 = Spliner::Spliner.new Hash[0.0, 0.0]
    expect(s1.get 0.0).to be_within(@two_epsilon).of(0.0)
    expect(s1.get 1.5).to be_nil

    s2 = Spliner::Spliner.new Hash[0.0, 0.0], :extrapolate => -1..1
    expect(s2.get 0.0).to be_within(@two_epsilon).of(0.0)
    expect(s2.get 0.5).to be_within(@two_epsilon).of(0.0)
  end

  it 'supports the Hash initializer' do
    s1 = Spliner::Spliner.new Hash[0.0, 0.0, 1.0, 1.0]
    expect(s1[0.5]).to be_within(@two_epsilon).of(0.5)

    s2 = Spliner::Spliner.new Hash[0.0, 0.0, 1.0, 1.0], :extrapolate => '100%'
    expect(s2[0.5]).to be_within(@two_epsilon).of(0.5)
    expect(s2.range.first).to be_within(@two_epsilon).of(-1.0)
  end

  it 'supports the x-y array/vector initializer' do
    s1 = Spliner::Spliner.new [0.0, 1.0], [0.0, 1.0]
    expect(s1[0.5]).to be_within(@two_epsilon).of(0.5)

    s2= Spliner::Spliner.new [0.0, 1.0], [0.0, 1.0], :extrapolate => '100%'
    expect(s2[0.5]).to be_within(@two_epsilon).of(0.5)
    expect(s2.range.first).to be_within(@two_epsilon).of(-1.0)

    s3 = Spliner::Spliner.new Vector[0.0, 1.0], Vector[0.0, 1.0]
    expect(s3[0.5]).to be_within(@two_epsilon).of(0.5)
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
    expect(s.get(0.4)).to be_within(@two_epsilon).of(0.5260)
    expect(s.get(0.8)).to be_within(@two_epsilon).of(0.9080)
    expect(s.get(1.2)).to be_within(@two_epsilon).of(1.0080)
    expect(s.get(1.6)).to be_within(@two_epsilon).of(0.8260)
  end

  it 'should perform linear interpolation in the case of two data points' do
    s = Spliner::Spliner.new({0 => 0, 10.0 => 100.0})
    expect(s.get(3.0)).to be_within(@two_epsilon).of(30.0)
  end

  it 'supports the [] operator (indexing like)' do
    s = Spliner::Spliner.new DATASET
    expect(s[-1]).to be_nil
    expect(s[0]).to be_within(@two_epsilon).of(0.0)
  end

  it 'performs :linear extrapolation outside the data range when such is given' do
    s = Spliner::Spliner.new KEYS_0_100, :extrapolate => -200..200
    expect(s.get -110).not_to be_nil
    expect(s.get -150).to be_within(1e-13).of(-150)
    expect(s.get 150).to be_within(1e-13).of(150)
  end

  it 'performs :hold extrapolation' do
    s = Spliner::Spliner.new KEYS_0_100, :extrapolate => -200..200, :emethod => :hold
    expect(s.get -150).to be_within(@two_epsilon).of(0)
    expect(s.get 150).to be_within(@two_epsilon).of(100)
  end

  it 'supports data ranges given as a string like "10%"' do
    s1 = Spliner::Spliner.new KEYS_0_100, :extrapolate => '10%'
    expect(s1.range.first).to be_within(@two_epsilon).of(-10.0)
    expect(s1.range.last).to be_within(@two_epsilon).of(110.0)

    s2 = Spliner::Spliner.new KEYS_0_100, :extrapolate => '10.0%'
    expect(s2.range.first).to be_within(@two_epsilon).of(-10.0)
    expect(s2.range.last).to be_within(@two_epsilon).of(110.0)

    s3 = Spliner::Spliner.new KEYS_0_100, :extrapolate => '10 %'
    expect(s3.range.first).to be_within(@two_epsilon).of(-10.0)
    expect(s3.range.last).to be_within(@two_epsilon).of(110.0)

    s4 = Spliner::Spliner.new KEYS_0_100, :extrapolate => 0.1
    expect(s3.range.first).to be_within(@two_epsilon).of(-10.0)
    expect(s3.range.last).to be_within(@two_epsilon).of(110.0)
  end

  it 'splits data points with duplicate X values into separate sections' do
    s = Spliner::Spliner.new [0.0, 1.0, 1.0, 2.0, 2.0, 3.0], [0.0, 0.0, 1.0, 1.0, 2.0, 2.0], :extrapolate => 3.0..4.0
    expect(s.sections).to eq(3)
    expect(s[-1.0]).to be_nil
    expect(s[0.5]).to be_within(@two_epsilon).of(0.0)
    expect(s[1.5]).to be_within(@two_epsilon).of(1.0)
    expect(s[2.5]).to be_within(@two_epsilon).of(2.0)
    expect(s[3.5]).to be_within(@two_epsilon).of(2.0)
    expect(s[5.0]).to be_nil
  end

  it 'should accept an array or vector as index' do
    s = Spliner::Spliner.new DATASET
    expect(s[*DATASET.keys]).to eq(DATASET.values)
    expect(s[DATASET.keys]).to eq(DATASET.values)
    expect(s[Vector[*DATASET.keys]]).to eq(Vector[*DATASET.values])
  end

  it 'should accept an range/enumerator as index' do
    s = Spliner::Spliner.new DATASET
    expect(s[0..2]).to eq(DATASET.values)
    expect(s[(0.0..2.0).step(1.0)]).to eq(DATASET.values)
  end

  it 'supports the class shortcut method' do
    expect(Spliner::Spliner[DATASET_X, DATASET_Y, 0..2]).to eq(DATASET.values)
    expect(Spliner::Spliner::interpolate(DATASET, 0..2, :extrapolate => '5%')).to eq(DATASET.values)
  end

  it 'has the option :fix_invalid_x to delete invalid x values (not increasing)' do
    s = Spliner::Spliner.new [0.0, -1.0, -1.1, 0.5, 0.4, 1.0], [0.0, 1.0, 1.0, 0.5, 1.0, 1.0], :extrapolate => '100%', :fix_invalid_x => true 
    expect(s[0.5]).to be_within(0.001).of(0.5)
    expect(s[-0.5]).to be_within(0.001).of(-0.5)

    # not sure why this one is more difficult
    x = [ -0.2006675899028778, -0.15321242064237595, -0.1328744888305664, -0.09355448558926582, -0.055590344592928886, -0.01355862058699131, 0.0, -0.008135172538459301, 0.0, -0.005423448514193296 ]
    y = [ -60.06944274902344, -53.81944274902344, -51.46846008300781, -46.78096008300781, -41.30497741699219, -35.9664306640625, -33.99884033203125, -32.79803466796875, -31.980606079101562, -31.163192749023438 ]
    s2 = Spliner::Spliner.new x, y, :fix_invalid_x => true 
  end

end
