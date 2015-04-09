def app_path
  ENV['APP_BUNDLE_PATH'] || (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH)
end

Given /^I launch the app$/ do
  # latest sdk and iphone by default
  ios_launch_app app_path, "8.2"
end

Given /^I launch the app using iOS (\d\.\d)$/ do |sdk|
  # You can grab a list of the installed SDK with sim_launcher
  # > run sim_launcher from the command line
  # > open a browser to http://localhost:8881/showsdks
  # > use one of the sdk you see in parenthesis (e.g. 4.2)
  ios_launch_app app_path, sdk
end

Given /^I launch the app using iOS (\d\.\d) and the (iphone|ipad) simulator$/ do |sdk, version|
  ios_launch_app app_path, sdk, version
end

def ios_launch_app(path, sdk, family = "iphone", args = {})
	case family
	when "iphone"
		device_type = "com.apple.CoreSimulator.SimDeviceType.iPhone-4s"
	when "ipad"
		device_type = "com.apple.CoreSimulator.SimDeviceType.iPad-2"
	else
		fail("Family is not supported: #{family}")
	end

	device_type_id = "#{device_type}, #{sdk}"

	if args.empty?
		command = "ios-sim launch #{path} --devicetypeid '#{device_type_id}' --exit"
	else
		arguments = args.map {|e| e.join(" ")}.join
		command = "ios-sim launch #{path} --devicetypeid '#{device_type_id}' --args #{arguments} --exit"
	end

	print(command)
	# run the command...
	system(command)

	# ...and wait until it starts listening Frank's default port
	frank_web_server_port=37265
	while !system("netstat -p tcp -an | grep -i listen | grep .#{frank_web_server_port}")
		# wait until the server begins listening to the configured port
		sleep 0.1
	end
end
