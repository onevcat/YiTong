import "./styles.css";

const root = document.querySelector<HTMLDivElement>("#app");

if (root != null) {
  root.innerHTML = `
    <div class="shell">
      <h1>YiTong</h1>
      <p>Web renderer placeholder bundle is loaded.</p>
    </div>
  `;
}
