<template>
  <Line :data="data" :options="options" />
</template>

<script lang="ts">
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from "chart.js";
import { Line } from "vue-chartjs";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

export default {
  name: "TSReleaseByLines",
  components: {
    Line,
  },
  props: ["theme"],
  data() {
    const data: [label: string, total: number, checker: number | null][] = [
      ["v0.8", 31691, null],
      ["v0.9", 70493, null],
      ["v1.0", 70470, null],
      ["v1.1", 71599, 5914],
      ["v1.3", 74157, 6233],
      ["v1.4", 77156, 7497],
      ["v1.5", 64389, 10356],
      ["v1.6", 70617, 11975],
      ["v1.7", 70827, 12259],
      ["v1.8", 75482, 13083],
      ["v2.0", 101437, 15413],
      ["v2.1", 116300, 16960],
      ["v2.2", 121649, 17440],
      ["v2.3", 127394, 18778],
      ["v2.4", 130602, 19179],
      ["v2.5", 134393, 19539],
      ["v2.6", 147204, 19934],
      ["v2.7", 153366, 20756],
      ["v2.8", 156955, 21403],
      ["v2.9", 167072, 22382],
      ["v3.0", 173682, 23265],
      ["v3.1", 180730, 24029],
      ["v3.2", 187227, 24641],
      ["v3.3", 195005, 25371],
      ["v3.4", 195438, 25395],
      ["v3.5", 197774, 25972],
      ["v3.6", 206488, 26980],
      ["v3.7", 215547, 28981],
      ["v3.8", 224261, 29837],
      ["v3.9", 229617, 30721],
      ["v4.0", 240172, 31702],
      ["v4.1", 244368, 32615],
      ["v4.2", 249624, 33189],
      ["v4.3", 261415, 34215],
      ["v4.4", 265228, 34676],
      ["v4.5", 269168, 35603],
      ["v4.6", 271921, 35841],
      ["v4.7", 275858, 36478],
      ["v4.8", 279077, 37028],
      ["v4.9", 280780, 37374],
      ["v5.0", 306081, 39501],
      ["main", 306454, 39701],
    ];

    return {
      data: {
        labels: data.map((x) => x[0]),
        datasets: [
          {
            label: "Lines of code in 'src'",
            backgroundColor: this.theme === "dark" ? "#ff5722" : "#285577",
            borderColor: this.theme === "dark" ? "#451100" : "#91bada",
            data: data.map((x) => x[1]),
          },
          {
            label: "Lines of code in 'checker.ts'",
            backgroundColor: this.theme === "dark" ? "lightgrey" : undefined,
            borderColor: this.theme === "dark" ? "grey" : undefined,
            data: data.map((x) => x[2]),
          },
        ],
      },
      options: {
        responsive: true,
        devicePixelRatio: 4,
        animation: {
          duration: 0,
        },
        scales: {
          x: {
            grid: {
              color: this.theme === "dark" ? "#222" : undefined,
            },
          },
          y: {
            beginAtZero: true,
            grid: {
              color: this.theme === "dark" ? "#222" : undefined,
            },
          },
        },
        // maintainAspectRatio: false,
      },
    };
  },
};
</script>
