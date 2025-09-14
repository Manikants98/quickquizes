"use client";

import {
  Badge,
  Box,
  Button,
  Card,
  Grid,
  Group,
  SimpleGrid,
  Stack,
  Text,
  Title,
} from "@mantine/core";
import { IconBrain, IconBulb, IconPlus } from "@tabler/icons-react";
import moment from "moment";
import Link from "next/link";
import { useEffect, useState } from "react";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { DashboardSkeleton } from "../components/SkeletonLoaders";

interface DashboardData {
  stats: {
    totalUsers: number;
    totalQuizzes: number;
    totalQuestions: number;
    totalAttempts: number;
  };
  recentActivities: any[];
  activityData: Array<{
    date: string;
    activities: number;
  }>;
  questions: any[];
  quizzes: any[];
  performanceMetrics: {
    avgScore: number;
    completionRate: number;
    userRetention: number;
    platformActivity: number;
  };
}

export default function DashboardPage() {
  const [dashboardData, setDashboardData] = useState<DashboardData | null>(
    null
  );
  const [loading, setLoading] = useState(true);

  const getPieChartColors = () => {
    const savedThemeColor =
      typeof window !== "undefined"
        ? localStorage.getItem("quickquiz-theme-color") || "blue"
        : "blue";
    const colorMaps = {
      green: ["#40c057", "#fab005", "#fd7e14", "#fa5252", "#7c3aed"],
      blue: ["#228be6", "#40c057", "#fab005", "#fd7e14", "#fa5252"],
      red: ["#fa5252", "#40c057", "#fab005", "#fd7e14", "#228be6"],
      violet: ["#7c3aed", "#40c057", "#fab005", "#fd7e14", "#fa5252"],
      orange: ["#fd7e14", "#40c057", "#fab005", "#fa5252", "#228be6"],
      pink: ["#e64980", "#40c057", "#fab005", "#fd7e14", "#fa5252"],
      teal: ["#12b886", "#40c057", "#fab005", "#fd7e14", "#fa5252"],
      indigo: ["#4c6ef5", "#40c057", "#fab005", "#fd7e14", "#fa5252"],
    };
    return (
      colorMaps[savedThemeColor as keyof typeof colorMaps] || colorMaps.blue
    );
  };

  const COLORS = getPieChartColors();
  const themeColors = {
    primary: "var(--mantine-primary-color-filled)",
    secondary: "var(--mantine-color-green-6)",
    gray: "var(--mantine-color-gray-6)",
  };

  const difficultyData =
    dashboardData?.questions.reduce((acc: any[], question: any) => {
      const existing = acc.find(
        (item) => item.difficulty === question.difficulty
      );
      if (existing) {
        existing.count += 1;
      } else {
        acc.push({ difficulty: question.difficulty, count: 1 });
      }
      return acc;
    }, []) || [];

  const quizStatsData =
    dashboardData?.quizzes.map((quiz: any) => ({
      name:
        quiz.title.length > 15
          ? quiz.title.substring(0, 15) + "..."
          : quiz.title,
      questions: quiz._count?.questions || 0,
      attempts: quiz._count?.quizAttempts || 0,
    })) || [];

  const recentActivityData =
    dashboardData?.activityData?.map((item: any) => ({
      day: moment(item.date).format("MMM DD"),
      activities: item.activities,
    })) || [];

  const fetchDashboardData = async () => {
    try {
      const response = await fetch("/api/v1/dashboard");
      const data = await response.json();
      if (data.success) {
        setDashboardData(data.data);
      } else {
        console.error("Error in dashboard response:", data.error);
      }
    } catch (error) {
      console.error("Error fetching dashboard data:", error);
    }
  };

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      try {
        await fetchDashboardData();
      } catch (error) {
        console.error("Error in dashboard data loading:", error);
      } finally {
        setLoading(false);
        console.log("Dashboard data loading complete");
      }
    };

    loadData();
  }, []);

  if (loading) {
    return (
      <Stack>
        <DashboardSkeleton />
      </Stack>
    );
  }

  return (
    <Stack>
      <Stack gap="lg">
        <Title order={2}>Dashboard Overview</Title>
        <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="lg">
          <Card withBorder>
            <Group justify="space-between" align="center" mb="xs">
              <Text size="sm" c="dimmed">
                AI Status
              </Text>
              <Badge
                color="green"
                variant="filled"
                size="sm"
                style={{
                  animation: "pulse 2s infinite",
                }}
              >
                Active
              </Badge>
            </Group>
            <Text size="xl" fw={700} c="green">
              Online
            </Text>
            <Text size="xs" c="dimmed">
              AI middleware running
            </Text>
          </Card>
          <Card withBorder>
            <Group justify="space-between" align="center" mb="xs">
              <Text size="sm" c="dimmed">
                Total Quizzes
              </Text>
              <Badge color="blue" variant="light" size="sm">
                {dashboardData?.stats.totalQuizzes || 0}
              </Badge>
            </Group>
            <Text size="xl" fw={700} c="blue">
              {dashboardData?.stats.totalQuizzes || 0}
            </Text>
            <Text size="xs" c="dimmed">
              Active quizzes
            </Text>
          </Card>
          <Card withBorder>
            <Group justify="space-between" align="center" mb="xs">
              <Text size="sm" c="dimmed">
                Questions
              </Text>
              <Badge color="orange" variant="light" size="sm">
                {dashboardData?.stats.totalQuestions || 0}
              </Badge>
            </Group>
            <Text size="xl" fw={700} c="orange">
              {dashboardData?.stats.totalQuestions || 0}
            </Text>
            <Text size="xs" c="dimmed">
              In question bank
            </Text>
          </Card>
          <Card withBorder>
            <Group justify="space-between" align="center" mb="xs">
              <Text size="sm" c="dimmed">
                Total Users
              </Text>
              <Badge color="violet" variant="light" size="sm">
                {dashboardData?.stats.totalUsers || 0}
              </Badge>
            </Group>
            <Text size="xl" fw={700} c="violet">
              {dashboardData?.stats.totalUsers || 0}
            </Text>
            <Text size="xs" c="dimmed">
              Registered users
            </Text>
          </Card>
        </SimpleGrid>

        <style
          dangerouslySetInnerHTML={{
            __html: `
            @keyframes pulse {
              0% { opacity: 1; transform: scale(1); }
              50% { opacity: 0.8; transform: scale(1.05); }
              100% { opacity: 1; transform: scale(1); }
            }
            .recharts-wrapper {
              outline: none !important;
            }
            .recharts-wrapper * {
              outline: none !important;
            }
            .recharts-pie-sector:focus,
            .recharts-pie-sector:active {
              stroke: var(--mantine-primary-color-filled) !important;
              stroke-width: 2px !important;
              filter: brightness(1.1);
            }
            .recharts-bar-rectangle:focus,
            .recharts-bar-rectangle:active {
              stroke: var(--mantine-primary-color-filled) !important;
              stroke-width: 2px !important;
              filter: brightness(1.1);
            }
            .recharts-area:focus,
            .recharts-area:active {
              stroke: var(--mantine-primary-color-filled) !important;
              stroke-width: 3px !important;
              filter: brightness(1.1);
            }
            .recharts-pie-sector:hover {
              filter: brightness(1.05);
              cursor: pointer;
            }
            .recharts-bar-rectangle:hover {
              filter: brightness(1.05);
              cursor: pointer;
            }
          `,
          }}
        />
        <SimpleGrid cols={{ base: 1, lg: 2 }} spacing="lg">
          <Card withBorder>
            <Title order={4} mb="md">
              Questions by Difficulty
            </Title>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={difficultyData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={(entry: any) => `${entry.difficulty}: ${entry.count}`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="count"
                >
                  {difficultyData.map((entry: any, index: number) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={COLORS[index % COLORS.length]}
                    />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Card>

          <Card withBorder>
            <Title order={4} mb="md">
              Quiz Statistics
            </Title>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={quizStatsData.slice(0, 6)}>
                <CartesianGrid
                  strokeDasharray="3 3"
                  stroke={themeColors.gray}
                  opacity={0.3}
                />
                <XAxis dataKey="name" tick={{ fill: themeColors.gray }} />
                <YAxis tick={{ fill: themeColors.gray }} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "var(--mantine-color-body)",
                    border: "1px solid var(--mantine-color-gray-3)",
                    borderRadius: "var(--mantine-radius-md)",
                    color: "var(--mantine-color-text)",
                  }}
                />
                <Bar
                  dataKey="questions"
                  fill={themeColors.primary}
                  name="Questions"
                />
                <Bar
                  dataKey="attempts"
                  fill={themeColors.secondary}
                  name="Attempts"
                />
              </BarChart>
            </ResponsiveContainer>
          </Card>
        </SimpleGrid>

        <Card withBorder>
          <Title order={4} mb="md">
            Activity Trend (Last 7 Days)
          </Title>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={recentActivityData}>
              <CartesianGrid
                strokeDasharray="3 3"
                stroke={themeColors.gray}
                opacity={0.3}
              />
              <XAxis dataKey="day" tick={{ fill: themeColors.gray }} />
              <YAxis tick={{ fill: themeColors.gray }} />
              <Tooltip
                contentStyle={{
                  backgroundColor: "var(--mantine-color-body)",
                  border: "1px solid var(--mantine-color-gray-3)",
                  borderRadius: "var(--mantine-radius-md)",
                  color: "var(--mantine-color-text)",
                }}
              />
              <Area
                type="monotone"
                dataKey="activities"
                stroke={themeColors.primary}
                fill={themeColors.primary}
                fillOpacity={0.2}
                strokeWidth={2}
              />
            </AreaChart>
          </ResponsiveContainer>
        </Card>

        <Grid>
          <Grid.Col span={{ base: 12, md: 8 }}>
            <Card withBorder h="100%">
              <Group justify="space-between" align="center" mb="md">
                <Title order={4}>Recent Activity</Title>
                <Badge color="gray" variant="light" size="sm">
                  {dashboardData?.recentActivities?.length || 0}
                </Badge>
              </Group>
              <Stack gap="md" h="100%" justify="space-between">
                <Box flex={1}>
                  {dashboardData?.recentActivities &&
                  dashboardData.recentActivities.length > 0 ? (
                    <Box style={{ position: "relative" }}>
                      {dashboardData.recentActivities
                        .slice(0, 5)
                        .map((activity: any, index: number) => (
                          <Box
                            key={index}
                            style={{
                              position: "relative",
                              paddingLeft: "40px",
                              marginBottom: index < 4 ? "16px" : "0",
                            }}
                          >
                            {/* Timeline line */}
                            {index < 4 && (
                              <Box
                                style={{
                                  position: "absolute",
                                  left: "19px",
                                  top: "32px",
                                  bottom: "-16px",
                                  width: "2px",
                                  backgroundColor:
                                    "var(--mantine-color-gray-3)",
                                }}
                              />
                            )}

                            {/* Timeline dot */}
                            <Box
                              style={{
                                position: "absolute",
                                left: "8px",
                                top: "8px",
                                width: "24px",
                                height: "24px",
                                borderRadius: "50%",
                                backgroundColor: activity.type.includes(
                                  "CREATED"
                                )
                                  ? "var(--mantine-color-green-6)"
                                  : activity.type.includes("UPDATED")
                                  ? "var(--mantine-color-blue-6)"
                                  : activity.type.includes("DELETED")
                                  ? "var(--mantine-color-red-6)"
                                  : "var(--mantine-color-gray-6)",
                                border: "3px solid var(--mantine-color-body)",
                                boxShadow:
                                  "0 0 0 2px var(--mantine-color-gray-3)",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                              }}
                            >
                              <Text size="xs" c="white" fw={600}>
                                {activity.user?.name
                                  ?.charAt(0)
                                  ?.toUpperCase() || "S"}
                              </Text>
                            </Box>

                            <Card
                              withBorder
                              radius="md"
                              p="md"
                              bg="var(--mantine-color-body)"
                              style={{
                                borderLeft: `3px solid ${
                                  activity.type.includes("CREATED")
                                    ? "var(--mantine-color-green-6)"
                                    : activity.type.includes("UPDATED")
                                    ? "var(--mantine-color-blue-6)"
                                    : activity.type.includes("DELETED")
                                    ? "var(--mantine-color-red-6)"
                                    : "var(--mantine-color-gray-6)"
                                }`,
                                transition: "transform 0.2s",
                                "&:hover": {
                                  transform: "translateX(4px)",
                                },
                              }}
                            >
                              <Group
                                justify="space-between"
                                align="flex-start"
                                wrap="nowrap"
                              >
                                <Box style={{ flex: 1, minWidth: 0 }}>
                                  <Group
                                    gap="xs"
                                    mb={4}
                                    align="flex-start"
                                    wrap="nowrap"
                                  >
                                    <Box>
                                      <Text size="sm" fw={500} lineClamp={1}>
                                        {activity.user?.name || "System"}
                                      </Text>
                                    </Box>
                                    <Badge
                                      color={
                                        activity.type.includes("CREATED")
                                          ? "green"
                                          : activity.type.includes("UPDATED")
                                          ? "blue"
                                          : activity.type.includes("DELETED")
                                          ? "red"
                                          : "gray"
                                      }
                                      variant="light"
                                      size="xs"
                                      radius="sm"
                                    >
                                      {activity.type
                                        .split("_")
                                        .map(
                                          (word: string) =>
                                            word.charAt(0) +
                                            word.slice(1).toLowerCase()
                                        )
                                        .join(" ")}
                                    </Badge>
                                  </Group>
                                  <Text
                                    size="sm"
                                    fw={500}
                                    style={{
                                      wordBreak: "break-word",
                                      display: "block",
                                      lineHeight: 1.4,
                                      marginBottom: 4,
                                    }}
                                  >
                                    {activity.title || "Activity"}
                                  </Text>
                                </Box>

                                <Text
                                  size="xs"
                                  c="dimmed"
                                  style={{
                                    whiteSpace: "nowrap",
                                    marginLeft: "12px",
                                    alignSelf: "flex-start",
                                  }}
                                >
                                  {moment(activity.time).calendar()}
                                </Text>
                              </Group>
                            </Card>
                          </Box>
                        ))}
                    </Box>
                  ) : (
                    <Card withBorder radius="sm" p="lg" bg="gray.0" h="100%">
                      <Stack align="center" justify="center" gap="xs" h="100%">
                        <Text size="sm" c="dimmed" ta="center" fw={500}>
                          No recent activity
                        </Text>
                        <Text size="xs" c="dimmed" ta="center">
                          Activity will appear here when users create, update,
                          or delete questions
                        </Text>
                      </Stack>
                    </Card>
                  )}
                </Box>
              </Stack>
            </Card>
          </Grid.Col>
          <Grid.Col span={{ base: 12, md: 4 }}>
            <Card withBorder h="100%">
              <Title order={4} mb="md">
                Quick Actions
              </Title>
              <Stack gap="xs" justify="flex-start" h="100%">
                <Button
                  component={Link}
                  href="/admin/questions/new"
                  variant="light"
                  leftSection={<IconPlus size="1rem" />}
                  fullWidth
                >
                  Question Create
                </Button>
                <Button
                  component={Link}
                  href="/admin/quizzes/new"
                  variant="light"
                  leftSection={<IconBrain size="1rem" />}
                  fullWidth
                >
                  Quiz Create
                </Button>
                <Button
                  component={Link}
                  href="/admin/questions/bulk"
                  variant="light"
                  leftSection={<IconBulb size="1rem" />}
                  fullWidth
                >
                  Bulk Generate
                </Button>
              </Stack>
            </Card>
          </Grid.Col>
        </Grid>
      </Stack>
    </Stack>
  );
}
