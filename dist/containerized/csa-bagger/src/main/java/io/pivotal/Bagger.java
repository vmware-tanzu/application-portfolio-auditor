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
 * Copyright 2019-2024 VMware, Inc.
 * SPDX-License-Identifier: Apache-2.0
 */
public class Bagger {

    private static final String DEFAULT_SEPARATOR = ",";

    public static final String SELECT_APPS =
            "select r.alias, a.name, a.score, a.findings, a.info_findings, a.id, r.id," +
                    " (select count(*) from findings f where f.application = a.name and f.pattern not in ('Lines of Code', 'Analyzed File')) as num_findings" +
                    " from applications a inner join runs r on r.id = a.run_id" +
                    " order by r.alias, a.name;";

    public static void main(final String[] args) throws SQLException, ClassNotFoundException {
        Class.forName("org.sqlite.JDBC");

        final String databasePath = args[0];
        final Connection conn = DriverManager.getConnection("jdbc:sqlite:" + databasePath);
        final Statement stmtApps = conn.createStatement();
        final ResultSet rsApps = stmtApps.executeQuery(SELECT_APPS);
        while (rsApps.next()) {
            final String systemName = rsApps.getString(1);
            final String name = rsApps.getString(2);
            final String score = rsApps.getString(3);
            final int findings = rsApps.getInt(4);
            final int infoFindings = rsApps.getInt(5);
            final long appId = rsApps.getLong(6);
            final long runId = rsApps.getLong(7);
            final long nonInfoFindings = rsApps.getLong(8);
            final int appEarNamesSeparatorIndex = name.indexOf("__");
			final String appName;
			final String earName;
            if(appEarNamesSeparatorIndex == -1) {
                //System.err.println("No ear detected for " + name);
                appName = name;
                earName = name;
            } else {
				appName = name.substring(0, appEarNamesSeparatorIndex);
				earName = name.substring(appEarNamesSeparatorIndex + 2);
			}

            // Fixing scores at 0.0 on applications without finding
            final String cleanedUpScore = (nonInfoFindings == 0L) ? "10.0" : score;

            System.out.println("    [INFO] Application: "+name+" - Findings: "+findings+" - Non-Info Findings: "+nonInfoFindings+" - Score: "+score);

            final Statement stmtTags = conn.createStatement();
            final ResultSet rsTags = stmtTags.executeQuery("select value from application_tags where application_id = " + appId);
            final List<String> appTags = new ArrayList<String>();
            while (rsTags.next()) {
                appTags.add(rsTags.getString(1));
            }
            rsTags.close();
            stmtTags.close();

            final long countRemoteEJB = countFindingsInApplication(conn, runId, name, Arrays.asList("Remote-EJB"));
            final long countWASImports = countFindingsInApplication(conn, runId, name, Arrays.asList("java-ws2liberty-import"));
            final long countIO = countFindingsInApplication(conn, runId, name, Arrays.asList("java-fileIO", "java-file-system", "java-websockets-import", "java-batchAnnotations", "java-nio"));
            final long countCustomFindings = countFindingsInApplication(conn, runId, name, Arrays.asList("custom-finding"));

            final String isEJB = containsAnyOf(appTags, Arrays.asList("ejb"));
            final String isJMS = containsAnyOf(appTags, Arrays.asList("jms", "messaging"));
            final String isJAXWS = containsAnyOf(appTags, Arrays.asList("jax-ws", "soap"));
            final String isJAXRS = containsAnyOf(appTags, Arrays.asList("jax-rs", "json"));
            final String isJPA = containsAnyOf(appTags, Arrays.asList("jpa", "jdbc"));
            final String isServlet = containsAnyOf(appTags, Arrays.asList("servlet"));
            final String isStruts = containsAnyOf(appTags, Arrays.asList("struts"));
            final String isJSF = containsAnyOf(appTags, Arrays.asList("jsf"));
            final String isSession = containsAnyOf(appTags, Arrays.asList("session"));
            final String isSpring = containsAnyOf(appTags, Arrays.asList("spring"));
            final String isJNI = containsAnyOf(appTags, Arrays.asList("jni"));
            final String isCustomTagFound = containsAnyOf(appTags, Arrays.asList("custom-tag"));

            final String resultFile = args.length > 1 ? args[1] : "paa.csv";

            final String separator = args.length > 2 ? args[2] : DEFAULT_SEPARATOR;

			final String text = systemName + separator + appName + separator + earName + separator + cleanedUpScore + separator + (findings - infoFindings)
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
				final Path path = Paths.get(resultFile);
				Files.write(path, Arrays.asList(text), StandardCharsets.UTF_8,
					Files.exists(path) ? StandardOpenOption.APPEND : StandardOpenOption.CREATE);
			} catch (final IOException e) {
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
        final String rulesAsSql = rules.stream()
                .map(s -> "'" + s + "'")
                .collect(Collectors.joining(","));
        final Statement stmt = conn.createStatement();
        final ResultSet rs = stmt.executeQuery("select count(*) from findings where application = '" + appName + "' and run_id = " + runId + " and rule in (" + rulesAsSql + ")");
        final long count = rs.getLong(1);
        rs.close();
        stmt.close();
        return count;
    }
}
