r = Ractor.new do
  puts "Hello, Ractor!"
  # pp "Hello, Ractor! 2" # => in 'Kernel#require': can not access non-shareable objects in constant Kernel::RUBYGEMS_ACTIVATION_MONITOR by non-main ractor. (Ractor::IsolationError)
end

r.take

