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
    const data: [label: string, total: number, nonTest: number | null, checker: number | null][] = [
      ["v0.8", 31691, null, null],
      ["v0.9", 70493, null, null],
      ["v1.0", 70470, null, null],
      ["v1.1", 60523, 53633, 5914],
      ["v1.3", 63081, 56596, 6233],
      ["v1.4", 65346, 58564, 7497],
      ["v1.5", 51782, 44481, 10356],
      ["v1.6", 58198, 50794, 11975],
      ["v1.7", 58497, 51165, 12259],
      ["v1.8", 62998, 55359, 13083],
      ["v2.0", 87139, 65751, 15413],
      ["v2.1", 102887, 81752, 16960],
      ["v2.2", 106806, 84820, 17440],
      ["v2.3", 112112, 90233, 18778],
      ["v2.4", 115707, 93248, 19179],
      ["v2.5", 119498, 95438, 19539],
      ["v2.6", 131833, 101381, 19934],
      ["v2.7", 137630, 105863, 20756],
      ["v2.8", 140905, 107681, 21403],
      ["v2.9", 150892, 113098, 22382],
      ["v3.0", 156503, 116583, 23265],
      ["v3.1", 163607, 120329, 24029],
      ["v3.2", 168647, 123327, 24641],
      ["v3.3", 176360, 127341, 25371],
      ["v3.4", 176793, 127503, 25395],
      ["v3.5", 178611, 128672, 25972],
      ["v3.6", 185032, 132771, 26980],
      ["v3.7", 194041, 139294, 28981],
      ["v3.8", 202708, 144614, 29837],
      ["v3.9", 208256, 148179, 30721],
      ["v4.0", 218691, 155869, 31702],
      ["v4.1", 222680, 159084, 32615],
      ["v4.2", 227897, 162205, 33189],
      ["v4.3", 240008, 166535, 34215],
      ["v4.4", 244789, 171139, 34676],
      ["v4.5", 248666, 174422, 35603],
      ["v4.6", 251088, 176312, 35841],
      ["v4.7", 254559, 179279, 36478],
      ["v4.8", 257766, 183611, 37028],
      ["v4.9", 259055, 185610, 37374],
      ["v5.0", 283948, 206089, 39501],
      ["main", 283129, 208990, 39701],
    ];

    return {
      data: {
        labels: data.map((x) => x[0]),
        datasets: [
          {
            label: "Lines of code in 'src'",
            backgroundColor: this.theme === "dark" ? "#ff5722" : "#285577",
            borderColor: this.theme === "dark" ? "#653100" : "#91bada",
            data: data.map((x) => x[1]),
          },
          //   {
          //     label: "Lines of code (without testing infrastructure)",
          //     backgroundColor: this.theme === "dark" ? "lightgrey" : undefined,
          //     borderColor: this.theme === "dark" ? "grey" : undefined,
          //     data: data.map((x) => x[2]),
          //   },
          {
            label: "Lines of code in 'checker.ts'",
            backgroundColor: this.theme === "dark" ? "lightgrey" : "grey",
            borderColor: this.theme === "dark" ? "grey" : "lightgrey",
            data: data.map((x) => x[3]),
          },
        ],
      },
      options: {
        responsive: true,
        devicePixelRatio: 5,
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
