#
# wait_helpers.rb
#
# Contains a set of helper methods that function that helps wait for conditions to be met
# in a proactive manner and other timing related helpers
#

# Time to wait for UI updates
UI_UPDATE_DELAY = 1.0.freeze
# Sleep duration for loops to avoid busy waiting
LOOP_DELAY = 0.1.freeze
# Time to wait for session context updates
SESSION_CONTEXT_UPDATE_DELAY = 1.0.freeze

# Helper method to ensure wait time with additional buffer
def wait_until_with_buffer(args, &block)
  original_timeout = args[:timeout] || ENV['WAIT_TIMEOUT'].to_i
  args_buffered = args.dup

  args_buffered[:timeout] = 60

  start_time = Time.now
  Frank::Cucumber::WaitHelper.wait_until(args_buffered) { block.call() }
  end_time = Time.now

  delta = end_time - start_time
  puts("wait_until exceeded timeout #{original_timeout}. Took #{delta}. #{caller[0]}") if delta > original_timeout
end

# Wait for the UI to finish processing an action
def wait_for_ui_to_update
  sleep(UI_UPDATE_DELAY)
end

# Similar to wait_until but won't fail if the condition is never true.
# wait_until is prefered, but this can be useful if the condition might not occur.
def wait_until_without_failing(timeout=UI_UPDATE_DELAY)
  start = Time.now
  while ((Time.now - start) <= timeout)
    break if yield
    sleep(WaitHelpers::LOOP_DELAY)
  end
end
