def memory_benchmark
  print_rss
  10.times do
    yield
    print_rss
  end
end

def print_rss
  printf "%s RSS: %9s", $PROGRAM_NAME, IO.popen(%W(ps -o rss= -p #{Process.pid})).read
end
