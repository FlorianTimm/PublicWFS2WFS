<%@page session="false"%><%@page import="java.net.*,java.io.*,javax.xml.bind.DatatypeConverter,java.util.regex.*"%><%@page trimDirectiveWhitespaces="true"%><%
HttpURLConnection urlConnection = null;

String urlStr = "http://" + request.getServerName() + ":" + request.getServerPort() + "/publicWFS/WFS";

String basicAuth = "";

if (request.getParameter("user") != null && request.getParameter("password") != null) {
	basicAuth = "Basic " + new String(DatatypeConverter.printBase64Binary((request.getParameter("user") + ":" + request.getParameter("password")).getBytes()));
	request.getSession().setAttribute("Authorization", basicAuth);
} else if (request.getSession().getAttribute("Authorization") != null) {
	basicAuth = (String) request.getSession().getAttribute("Authorization");
} else if (request.getHeader("Authorization") != null) {
	basicAuth = (String) request.getHeader("Authorization");
	request.getSession().setAttribute("Authorization", basicAuth);
}

if (basicAuth == null || basicAuth.length() < 12) {
	response.setStatus(401);
	response.addHeader("WWW-Authenticate", "Basic realm=\"Login zum publicWFS\"");
	return;
}

try { 
	String reqUrl = request.getQueryString(); 
	
	if (reqUrl == null) {
		reqUrl = "";
	} else {
		reqUrl = "?" + reqUrl;
	}
	
	urlStr += reqUrl;
	
	URL url = new URL(urlStr);
	urlConnection = (HttpURLConnection) url.openConnection();

	if (basicAuth != null) {
		urlConnection.setRequestProperty("Authorization", basicAuth);
	}
	
	
	urlConnection.setDoOutput(true);
	urlConnection.setRequestMethod(request.getMethod());
	String reqContenType = request.getContentType();
	if(reqContenType != null) {
		urlConnection.setRequestProperty("Content-Type", reqContenType);
	}
	else {
		urlConnection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
	}
	
	int clength = request.getContentLength();
	if(clength > 0) {
		InputStream is = request.getInputStream(); 
		BufferedInputStream in = new BufferedInputStream(is);
		
		byte[] contents = new byte[1024];

		int bytesRead = 0;
		String strFileContents = ""; 
		urlConnection.setDoInput(true);
		while((bytesRead = in.read(contents)) != -1) { 
			//strFileContents += new String(contents, 0, bytesRead);
			urlConnection.getOutputStream().write(contents, 0, bytesRead);				
		}
	}
	//out.print(strFileContents);
	

	int statusCode = urlConnection.getResponseCode();
	response.setStatus(statusCode);

	InputStream inputStream = null;
	try {
		inputStream = urlConnection.getInputStream();
	} catch (IOException ioe) {
		if (statusCode != 200) {
			inputStream = urlConnection.getErrorStream();
		}
	}

	response.setContentType("text/xml");
	response.setCharacterEncoding("ISO-8859-1");

	BufferedReader rd = new BufferedReader(new InputStreamReader(inputStream));
	String inputLine;
	int i = 0;
	while ((inputLine = rd.readLine()) != null) {
		inputLine = inputLine.replaceAll(urlStr, request.getRequestURL().toString());

		String patternStr = " luk=\"(.{1,6})\">()<\\/";
		Pattern pattern = Pattern.compile(patternStr);
		Matcher matcher = pattern.matcher(inputLine);
		int last_index = 0;
		String outputLine = "";
		while(matcher.find()){
			out.print(inputLine.substring(last_index, matcher.start(2)));
			last_index = matcher.start(2);
			out.print(matcher.group(1));
		}
		out.println(inputLine.substring(last_index));	
	}
	rd.close();
} catch(Exception e) {
	response.setStatus(500);
	e.printStackTrace(response.getWriter());
	out.println("ERROR 500: An internal server error occured. " + e.getMessage());	
}
%>