package io.pivotal;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.sql.*;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Copyright 2019-2023 VMware, Inc.
 * SPDX-License-Identifier: Apache-2.0
 */
public class Bagger {

    private static final String DEFAULT_SEPARATOR = ",";

    public static final String SELECT_APPS =
            "select r.alias, a.name, a.score, a.findings, a.info_findings, a.id, r.id" +
                    " from applications a inner join runs r on r.id = a.run_id" +
                    " order by r.alias, a.name;";

    public static void main(String[] args) throws SQLException, ClassNotFoundException {
        Class.forName("org.sqlite.JDBC");

        String databasePath = args[0];
        Connection conn = DriverManager.getConnection("jdbc:sqlite:" + databasePath);
        Statement stmtApps = conn.createStatement();
        ResultSet rsApps = stmtApps.executeQuery(SELECT_APPS);
        while (rsApps.next()) {
            String systemName = rsApps.getString(1);
            String name = rsApps.getString(2);
            BigDecimal score = rsApps.getBigDecimal(3);
            int findings = rsApps.getInt(4);
            int infoFindings = rsApps.getInt(5);
            long appId = rsApps.getLong(6);
            long runId = rsApps.getLong(7);
            int appEarNamesSeparatorIndex = name.indexOf("__");
			String appName;
			String earName;
            if(appEarNamesSeparatorIndex == -1) {
                //System.err.println("No ear detected for " + name);
                appName = name;
                earName = name;
            } else {
				appName = name.substring(0, appEarNamesSeparatorIndex);
				earName = name.substring(appEarNamesSeparatorIndex + 2);
			}

            Statement stmtTags = conn.createStatement();
            ResultSet rsTags = stmtTags.executeQuery("select value from application_tags where application_id = " + appId);
            List<String> appTags = new ArrayList<String>();
            while (rsTags.next()) {
                appTags.add(rsTags.getString(1));
            }
            rsTags.close();
            stmtTags.close();

            long countRemoteEJB = countFindingsInApplication(conn, runId, name, Arrays.asList("Remote-EJB"));
            long countWASImports = countFindingsInApplication(conn, runId, name, Arrays.asList("java-ws2liberty-import"));
            long countIO = countFindingsInApplication(conn, runId, name, Arrays.asList("java-fileIO", "java-file-system", "java-websockets-import", "java-batchAnnotations", "java-nio"));
            long countCustomFindings = countFindingsInApplication(conn, runId, name, Arrays.asList("custom-finding"));

            String isEJB = containsAnyOf(appTags, Arrays.asList("ejb"));
            String isJMS = containsAnyOf(appTags, Arrays.asList("jms", "messaging"));
            String isJAXWS = containsAnyOf(appTags, Arrays.asList("jax-ws", "soap"));
            String isJAXRS = containsAnyOf(appTags, Arrays.asList("jax-rs", "json"));
            String isJPA = containsAnyOf(appTags, Arrays.asList("jpa", "jdbc"));
            String isServlet = containsAnyOf(appTags, Arrays.asList("servlet"));
            String isStruts = containsAnyOf(appTags, Arrays.asList("struts"));
            String isJSF = containsAnyOf(appTags, Arrays.asList("jsf"));
            String isSession = containsAnyOf(appTags, Arrays.asList("session"));
            String isSpring = containsAnyOf(appTags, Arrays.asList("spring"));
            String isJNI = containsAnyOf(appTags, Arrays.asList("jni"));
            String isCustomTagFound = containsAnyOf(appTags, Arrays.asList("custom-tag"));

            String resultFile = args.length > 1 ? args[1] : "paa.csv";

            String separator = args.length > 2 ? args[2] : DEFAULT_SEPARATOR;

			String text = systemName + separator + appName + separator + earName + separator + score + separator + (findings - infoFindings)
				+ separator + isEJB
				+ separator + countRemoteEJB
				+ separator + isJMS
				+ separator + isJAXWS
				+ separator + isJAXRS
				+ separator + isJPA
				+ separator + isServlet
				+ separator + isStruts
				+ separator + isJSF
				+ separator + isSession
				+ separator + isSpring
				+ separator + countWASImports
				+ separator + countIO
				+ separator + isJNI
				+ separator + isCustomTagFound
				+ separator + countCustomFindings
				;

			try {
				Path path = Paths.get(resultFile);
				Files.write(path, Arrays.asList(text), StandardCharsets.UTF_8,
					Files.exists(path) ? StandardOpenOption.APPEND : StandardOpenOption.CREATE);
			} catch (IOException e) {
				System.err.println("Something wrong with writing text to paa.csv");
			}
        }
        rsApps.close();
        stmtApps.close();
        conn.close();
    }

    private static String containsAnyOf(List<String> appTags, List<String> tags) {
        return !Collections.disjoint(appTags, tags) ? "Y" : "N";
    }

    private static long countFindingsInApplication(Connection conn, long runId, String appName, Collection<String> rules) throws SQLException {
        String rulesAsSql = rules.stream()
                .map(s -> "'" + s + "'")
                .collect(Collectors.joining(","));
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("select count(*) from findings where application = '" + appName + "' and run_id = " + runId + " and rule in (" + rulesAsSql + ")");
        long count = rs.getLong(1);
        rs.close();
        stmt.close();
        return count;
    }
}
