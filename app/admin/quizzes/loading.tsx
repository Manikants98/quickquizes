"use client";

import { Stack, Title, Group, Button } from "@mantine/core";
import { IconPlus } from "@tabler/icons-react";
import { QuizzesGridSkeleton } from "../components/SkeletonLoaders";

const Loading = () => {
  return (
    <Stack>
      <Stack gap="lg">
        <Group justify="space-between">
          <Title order={2}>Quiz Management</Title>
          <Button leftSection={<IconPlus size="1rem" />} disabled loading>
            Create Quiz
          </Button>
        </Group>

        <QuizzesGridSkeleton />
      </Stack>
    </Stack>
  );
};

export default Loading;
