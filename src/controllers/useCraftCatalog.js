import { useMemo, useState } from "react";
import { crafts as defaultCrafts } from "../models/crafts.js";

export function useCraftCatalog(crafts = defaultCrafts) {
  const [activeCategory, setActiveCategory] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");

  const visibleCrafts = useMemo(() => {
    const query = searchTerm.trim().toLocaleLowerCase();

    return crafts.filter((craft) => {
      const matchesCategory =
        activeCategory === "all" || craft.category === activeCategory;
      const matchesSearch = `${craft.name} ${craft.categoryLabel} ${craft.description}`
        .toLocaleLowerCase()
        .includes(query);

      return matchesCategory && matchesSearch;
    });
  }, [activeCategory, crafts, searchTerm]);

  return {
    activeCategory,
    setActiveCategory,
    searchTerm,
    setSearchTerm,
    visibleCrafts,
  };
}
