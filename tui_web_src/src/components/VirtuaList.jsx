import { VList } from "virtua/solid";

export default function VirtuaList() {
  const sizes = [20, 40, 80, 77];
  const data = Array.from({ length: 1000 }).map((_, i) => sizes[i % 4]);
  console.log("loaded", sizes, data);
  return (
    <VList data={data} style={{ height: "800px", background: "#cccccc" }}>
      {(d, i) => (
        console.log("t"),
        (
          <div
            style={{
              height: d + "px",
              "border-bottom": "solid 1px #ccc",
              background: "#fff",
            }}
          >
            {i}
          </div>
        )
      )}
    </VList>
  );
}
