"use client";

import {
  Box,
  Card,
  Group,
  Progress,
  SimpleGrid,
  Stack,
  Text,
  Title,
} from "@mantine/core";
import {
  IconMinus,
  IconTrendingDown,
  IconTrendingUp,
} from "@tabler/icons-react";
import { useEffect, useState } from "react";
import { Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { AnalyticsSkeleton } from "../components/SkeletonLoaders";

interface Analytics {
  totalUsers: number;
  totalQuizzes: number;
  totalQuestions: number;
  totalAttempts: number;
  recentActivity: any[];
  recentActivities: any[];
  activity: any[];
  popularCategories: any[];
  questionDifficulties: { difficulty: string; count: number }[];
  performanceMetrics: {
    avgScore: number;
    completionRate: number;
    userRetention: number;
    platformActivity: number;
  };
  activeUsers: {
    count: number;
    percentage: number;
    total: number;
  };
}

export default function AnalyticsPage() {
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchAnalytics = async () => {
    try {
      const response = await fetch("/api/v1/analytics");
      const data = await response.json();
      if (data.success) {
        // Map the response data to match our Analytics interface
        const formattedData = {
          ...data.data,
          recentActivity: data.data.recentActivities || [],
          popularCategories: [],
        };
        setAnalytics(formattedData);
      }
    } catch (error) {
      console.error("Error fetching analytics:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, []);
  //mkx
  return (
    <Stack>
      {loading ? (
        <AnalyticsSkeleton />
      ) : (
        <Stack gap="lg">
          <Title order={2}>Analytics Dashboard</Title>
          <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="lg" style={{ alignItems: "stretch" }}>
            <Card withBorder h="100%">
              <Group justify="space-between" align="flex-start">
                <Box>
                  <Text size="sm" c="dimmed">
                    Total Users
                  </Text>
                  <Text size="xl" fw={700}>
                    {analytics?.totalUsers || 0}
                  </Text>
                </Box>
                <IconTrendingUp size={20} color="green" />
              </Group>
            </Card>

            <Card withBorder h="100%">
              <Group justify="space-between" align="flex-start">
                <Box>
                  <Text size="sm" c="dimmed">
                    Active Users
                  </Text>
                  <Text size="xl" fw={700}>
                    {analytics?.activeUsers?.count || 0}
                  </Text>
                </Box>
                <IconTrendingUp size={20} color="teal" />
              </Group>
            </Card>

            <Card withBorder h="100%">
              <Group justify="space-between" align="flex-start">
                <Box>
                  <Text size="sm" c="dimmed">
                    Total Quizzes
                  </Text>
                  <Text size="xl" fw={700}>
                    {analytics?.totalQuizzes || 0}
                  </Text>
                </Box>
                <IconTrendingUp size={20} color="blue" />
              </Group>
            </Card>

            <Card withBorder h="100%">
              <Group justify="space-between" align="flex-start">
                <Box>
                  <Text size="sm" c="dimmed">
                    Total Questions
                  </Text>
                  <Text size="xl" fw={700}>
                    {analytics?.totalQuestions || 0}
                  </Text>
                </Box>
                <IconTrendingUp size={20} color="green" />
              </Group>
            </Card>

            <Card withBorder h="100%">
              <Group justify="space-between" align="flex-start">
                <Box>
                  <Text size="sm" c="dimmed">
                    Quiz Attempts
                  </Text>
                  <Text size="xl" fw={700}>
                    {analytics?.totalAttempts || 0}
                  </Text>
                </Box>
                <IconTrendingDown size={20} color="red" />
              </Group>
            </Card>

            <Card withBorder h="100%">
              <Group justify="space-between" align="flex-start">
                <Box>
                  <Text size="sm" c="dimmed">
                    Avg. Score
                  </Text>
                  <Text size="xl" fw={700}>
                    {analytics?.performanceMetrics?.avgScore || 0}%
                  </Text>
                </Box>
                <IconTrendingUp size={20} color="green" />
              </Group>
            </Card>

            <Card withBorder h="100%">
              <Group justify="space-between" align="flex-start">
                <Box>
                  <Text size="sm" c="dimmed">
                    Completion Rate
                  </Text>
                  <Text size="xl" fw={700}>
                    {analytics?.performanceMetrics?.completionRate || 0}%
                  </Text>
                </Box>
                <IconTrendingUp size={20} color="blue" />
              </Group>
            </Card>

            <Card withBorder h="100%">
              <Group justify="space-between" align="flex-start">
                <Box>
                  <Text size="sm" c="dimmed">
                    Platform Activity
                  </Text>
                  <Text size="xl" fw={700}>
                    {analytics?.performanceMetrics?.platformActivity || 0}%
                  </Text>
                </Box>
                <IconMinus size={20} color="gray" />
              </Group>
            </Card>
          </SimpleGrid>

          <SimpleGrid cols={{ base: 1, md: 2 }} spacing="lg">
            <Card withBorder>
              <Title order={5} mb="md">
                Question Difficulty Distribution
              </Title>
              {analytics?.questionDifficulties &&
              analytics.questionDifficulties.length > 0 ? (
                <ResponsiveContainer width="100%" height={200}>
                  <PieChart>
                    <Pie
                      data={analytics.questionDifficulties.map((item) => ({
                        name:
                          item.difficulty.charAt(0) +
                          item.difficulty.slice(1).toLowerCase(),
                        value: item.count,
                        fill:
                          item.difficulty === "EASY"
                            ? "#51cf66"
                            : item.difficulty === "MEDIUM"
                            ? "#ffd43b"
                            : "#ff8787",
                      }))}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={(entry: any) => `${entry.name}: ${entry.value}`}
                      outerRadius={60}
                      dataKey="value"
                    />
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              ) : (
                <Box ta="center" py="xl">
                  <Text size="sm" c="dimmed">
                    No question difficulty data available
                  </Text>
                </Box>
              )}
              <Group justify="center" gap="md" mt="sm">
                <Group gap={4}>
                  <Box w={12} h={12} bg="#51cf66" style={{ borderRadius: 2 }} />
                  <Text size="xs">Easy</Text>
                </Group>
                <Group gap={4}>
                  <Box w={12} h={12} bg="#ffd43b" style={{ borderRadius: 2 }} />
                  <Text size="xs">Medium</Text>
                </Group>
                <Group gap={4}>
                  <Box w={12} h={12} bg="#ff8787" style={{ borderRadius: 2 }} />
                  <Text size="xs">Hard</Text>
                </Group>
              </Group>
            </Card>

            <Card withBorder>
              <Title order={5} mb="md">
                Performance Metrics
              </Title>
              <Stack gap="md">
                <Box>
                  <Group justify="space-between" mb={4}>
                    <Text size="sm">Average Quiz Score</Text>
                    <Text size="sm" fw={500}>
                      {analytics?.performanceMetrics?.avgScore || 0}%
                    </Text>
                  </Group>
                  <Progress
                    value={analytics?.performanceMetrics?.avgScore || 0}
                    size="sm"
                    color="blue"
                  />
                </Box>

                <Box>
                  <Group justify="space-between" mb={4}>
                    <Text size="sm">Quiz Completion Rate</Text>
                    <Text size="sm" fw={500}>
                      {analytics?.performanceMetrics?.completionRate || 0}%
                    </Text>
                  </Group>
                  <Progress
                    value={analytics?.performanceMetrics?.completionRate || 0}
                    size="sm"
                    color="green"
                  />
                </Box>

                <Box>
                  <Group justify="space-between" mb={4}>
                    <Text size="sm">User Retention</Text>
                    <Text size="sm" fw={500}>
                      {analytics?.performanceMetrics?.userRetention || 0}%
                    </Text>
                  </Group>
                  <Progress
                    value={analytics?.performanceMetrics?.userRetention || 0}
                    size="sm"
                    color="teal"
                  />
                </Box>

                <Box>
                  <Group justify="space-between" mb={4}>
                    <Text size="sm">Platform Activity</Text>
                    <Text size="sm" fw={500}>
                      {analytics?.performanceMetrics?.platformActivity || 0}%
                    </Text>
                  </Group>
                  <Progress
                    value={analytics?.performanceMetrics?.platformActivity || 0}
                    size="sm"
                    color="orange"
                  />
                </Box>
              </Stack>
            </Card>
          </SimpleGrid>
        </Stack>
      )}
    </Stack>
  );
}
