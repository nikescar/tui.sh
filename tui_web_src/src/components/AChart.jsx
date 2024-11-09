import { createSignal, onMount } from "solid-js";
import { SolidApexCharts } from "solid-apexcharts";

export default function AChart() {
  const [options] = createSignal({
    xaxis: {
      categories: [1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998],
    },
  });
  const [series] = createSignal([
    {
      name: "series-1",
      data: [30, 40, 35, 50, 49, 60, 70, 91],
    },
  ]);

  return (
    <SolidApexCharts
      width="500"
      type="bar"
      options={options()}
      series={series()}
    />
  );
}
