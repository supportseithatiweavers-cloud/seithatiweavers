import cushionCraft from "../../Gemini_Generated_Image_3nna743nna743nna.jpg";
import wovenBlankets from "../../Gemini_Generated_Image_6onwlh6onwlh6onw.jpg";
import wovenWallArt from "../../Gemini_Generated_Image_6onwlh6onwlh6onw (1).jpg";
import wovenBags from "../../Gemini_Generated_Image_6onwlh6onwlh6onw (2).jpg";
import woolCraft from "../../Gemini_Generated_Image_6onwlh6onwlh6onw (3).jpg";
import mohairCraft from "../../Gemini_Generated_Image_7w1kuv7w1kuv7w1k.jpg";

export const categories = [
  { id: "all", label: "All crafts" },
  { id: "bags", label: "Bags" },
  { id: "home", label: "Home decor" },
  { id: "accessories", label: "Accessories" },
  { id: "wearables", label: "Wearables" },
];

export const categoryShowcases = [
  {
    id: "bags",
    eyebrow: "Wearable art",
    title: "Handwoven bags",
    image: wovenBags,
    alt: "Handmade wool bags with Basotho-inspired designs",
  },
  {
    id: "home",
    eyebrow: "Warm spaces",
    title: "Home textiles",
    image: wovenBlankets,
    alt: "Colourful wool blankets draped over a wooden bench",
  },
  {
    id: "accessories",
    eyebrow: "Made to be loved",
    title: "Woven keepsakes",
    image: wovenWallArt,
    alt: "Small handmade woven wall hangings and textile pieces",
  },
];

export const crafts = [
  {
    id: "woven-wool-handbag",
    category: "bags",
    categoryLabel: "Bags & accessories",
    name: "Woven wool handbag",
    description: "A characterful carryall, made by hand in colourful wool.",
    image: wovenBags,
    alt: "Two handmade wool bags with traditional house motifs",
    badge: "Handwoven",
  },
  {
    id: "woven-wool-rug",
    category: "home",
    categoryLabel: "Home decor",
    name: "Woven wool rug",
    description: "Bring colour, warmth and texture into your living space.",
    image: wovenBlankets,
    alt: "Traditional patterned wool blankets on a wooden bench",
    badge: "Home craft",
  },
  {
    id: "wool-wall-hanging",
    category: "home",
    categoryLabel: "Home decor",
    name: "Wool wall hanging",
    description: "A handcrafted textile accent with a story in every thread.",
    image: wovenWallArt,
    alt: "Handwoven wool wall art and small textile hangings",
    badge: "Made in Lesotho",
  },
  {
    id: "mohair-throw",
    category: "home",
    categoryLabel: "Home decor",
    name: "Mohair throw",
    description: "A soft, inviting layer for quiet evenings at home.",
    image: mohairCraft,
    alt: "Soft handmade mohair throws and wool pieces",
    badge: "Natural fibre",
  },
  {
    id: "wool-scarf",
    category: "accessories",
    categoryLabel: "Accessories",
    name: "Wool scarf",
    description: "A cosy everyday accessory shaped by skilled hands.",
    image: woolCraft,
    alt: "Handmade wool accessories and woven home crafts",
    badge: "Handmade",
  },
  {
    id: "woven-cushion",
    category: "home",
    categoryLabel: "Home decor",
    name: "Woven cushion",
    description: "Add natural texture and a touch of craft to your home.",
    image: cushionCraft,
    alt: "Cream-coloured handmade wool cushions on a sofa",
    badge: "Home craft",
  },
  {
    id: "wool-accessories",
    category: "wearables",
    categoryLabel: "Wearables",
    name: "Wool accessories",
    description: "Thoughtful handmade pieces for warmth and personal style.",
    image: woolCraft,
    alt: "Woollen handmade crafts made from natural fibres",
    badge: "Made with care",
  },
  {
    id: "mohair-blanket",
    category: "home",
    categoryLabel: "Home decor",
    name: "Mohair blanket",
    description: "A timeless textile celebrating the beauty of mohair.",
    image: mohairCraft,
    alt: "Textured mohair blanket with other wool creations",
    badge: "Mohair",
  },
];

export const craftSteps = [
  {
    number: "01",
    label: "Material",
    title: "Natural fibres",
    description:
      "Local wool and mohair provide the foundation for beautiful, lasting handmade creations.",
    image: woolCraft,
    alt: "Handmade wool crafts showing the texture of natural fibres",
  },
  {
    number: "02",
    label: "Craft",
    title: "Skilled hands",
    description:
      "Every piece reflects the time, creativity and experience of the women who make it.",
    image: wovenWallArt,
    alt: "Handwoven textile artwork made by skilled craftspeople",
  },
  {
    number: "03",
    label: "Creation",
    title: "Made to be shared",
    description:
      "Heritage and everyday usefulness come together in each finished piece.",
    image: mohairCraft,
    alt: "Finished wool and mohair creations ready to be enjoyed",
  },
];

export const storyImage = wovenWallArt;
export const callToActionImage = wovenBlankets;
